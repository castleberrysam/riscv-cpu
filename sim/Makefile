SRCS := ../test/tb_top.sv $(wildcard ../src/*.sv) ../micron/ddr3.v
HDRS := $(wildcard ../src/*.vh)

LIBS := -L unimacro_ver -L unisims_ver -L secureip
DEFINES := -d XILINX -d den2048Mb -d sg15E -d x16

MIG_DIR := ../fpga/ip/dram_mig/dram_mig/user_design/rtl

.PHONY: all run clean

all: axsim.sh

axsim.sh: xsim.dir/work/work.rlx
	xelab -a --relax $(DEFINES) $(LIBS) tb_top glbl
	sed -i -e '5i cd "$${BASH_SOURCE%/*}"' axsim.sh

xsim.dir/work/work.rlx: $(SRCS) $(HDRS) ../fpga/ip
	xvlog --sv --relax $(DEFINES) $(SRCS)
	xvlog --relax $(MIG_DIR)/dram_mig.v $(MIG_DIR)/dram_mig_mig_sim.v $(shell find $(MIG_DIR) -mindepth 2 -type f -name \*.v) $(XILINX_VIVADO)/data/verilog/src/glbl.v

../fpga/ip:
	make -C ../fpga ip

clean:
	-rm -r axsim.sh *.jou *.log *.pb *.vcd .Xil/ xsim.dir/
