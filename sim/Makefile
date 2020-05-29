SRCS := ../test/tb_top.v $(wildcard ../src/*.v)
HDRS := $(wildcard ../src/*.vh)

.PHONY: all run clean

all: axsim.sh

axsim.sh: xsim.dir/work/work.rlx
	xelab -a --relax -d XILINX tb_top
	sed -i -e '5i cd "$${BASH_SOURCE%/*}"' axsim.sh

xsim.dir/work/work.rlx: $(SRCS) $(HDRS)
	xvlog --relax -d XILINX $(SRCS)

clean:
	-rm -r axsim.sh *.jou *.log *.pb .Xil/ xsim.dir/
