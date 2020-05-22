FROM debian:buster AS base
# general build stuff
RUN apt update && apt install -y sudo curl git make g++ python3 pkg-config flex bison
# create user debian
RUN useradd -m -s /bin/bash -G sudo debian \
    && echo 'debian ALL=(ALL) NOPASSWD:ALL' > /etc/sudoers.d/debian_nopasswd
WORKDIR /home/debian
USER debian

# build iverilog
FROM base AS iverilog
RUN curl -LO ftp://icarus.com/pub/eda/verilog/v10/verilog-10.3.tar.gz \
    && tar xaf verilog-10.3.tar.gz && rm verilog-10.3.tar.gz
RUN cd verilog-10.3 \
    && mkdir build && cd build \
    && ../configure && make -j5

# build riscv qemu
FROM base AS qemu
RUN sudo apt install -y libglib2.0-dev libpixman-1-dev
RUN curl -LO https://download.qemu.org/qemu-5.0.0.tar.xz \
    && tar xaf qemu-5.0.0.tar.xz && rm qemu-5.0.0.tar.xz
RUN cd qemu-5.0.0 \
    && mkdir build && cd build \
    && sudo sed -i -e 's/BITS_PER_LONG/__BITS_PER_LONG/g' /usr/include/linux/swab.h \
    && ../configure --target-list=riscv32-softmmu && make -j5

# build binutils
FROM base AS binutils
RUN sudo apt install -y texinfo libexpat-dev libncurses5-dev python3-distutils python3-dev
RUN git clone --depth 1 -b riscv-binutils-2.34 https://github.com/riscv/riscv-binutils-gdb.git
RUN cd riscv-binutils-gdb \
    && mkdir build && cd build \
    && ../configure --target=riscv64-linux-gnu --program-prefix=riscv64-linux-gnu- --enable-unit-tests --enable-tui --with-python=python3 && make -j5

# build yosys
FROM base AS yosys
RUN sudo apt install -y tcl-dev libreadline-dev libffi-dev
RUN curl -LO https://github.com/cliffordwolf/yosys/archive/yosys-0.9.tar.gz \
    && tar xaf yosys-0.9.tar.gz && rm yosys-0.9.tar.gz
RUN cd yosys-yosys-0.9 \
    && make config-gcc && make -j5

FROM base
# install all the stuff
COPY --from=iverilog /home/debian .
RUN sudo make -C verilog-10.3/build install && rm -rf verilog-10.3
COPY --from=qemu /home/debian .
RUN sudo apt install -y libglib2.0-dev libpixman-1-dev \
    && sudo make -C qemu-5.0.0/build install && rm -rf qemu-5.0.0
COPY --from=binutils /home/debian .
RUN sudo apt install -y python3-dev \
    && sudo make -C riscv-binutils-gdb/build install && rm -rf riscv-binutils-gdb
COPY --from=yosys /home/debian .
RUN sudo apt install -y tcl-dev libreadline-dev \
    && sudo make -C yosys-yosys-0.9 install && rm -rf yosys-yosys-0.9

# build project
RUN sudo apt install -y xxd
RUN echo 'set auto-load safe-path /' > ~/.gdbinit
COPY --chown=debian:debian . riscv-cpu
WORKDIR riscv-cpu
RUN make

CMD ["/bin/bash"]
