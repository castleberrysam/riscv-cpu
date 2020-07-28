SRCS := ../test/tb_top.sv $(wildcard ../src/*.sv) ../micron/ddr3.v
HDRS := $(wildcard ../src/*.svh)

LIBS := -L unimacro_ver -L unisims_ver -L secureip
DEFINES := -d XILINX -d den2048Mb -d sg15E -d x16

MIG_DIR := ../fpga/ip/dram_mig/dram_mig/user_design/rtl

.PHONY: all clean xsim

all: axsim.sh

xsim: xsim.dir/work/work.rlx xsim.dir/dram_mig/dram_mig.rlx xsim.dir/glbl/glbl.rlx
	xelab --relax $(DEFINES) $(LIBS) -L dram_mig tb_top glbl.glbl
	xsim work.tb_top#glbl.glbl --testplusarg memfile=../test/$(TEST).hex

axsim.sh: xsim.dir/work/work.rlx xsim.dir/dram_mig/dram_mig.rlx xsim.dir/glbl/glbl.rlx
	xelab --relax -a $(DEFINES) $(LIBS) -L dram_mig tb_top glbl.glbl
	sed -i -e '5i cd "$${BASH_SOURCE%/*}"' axsim.sh

xsim.dir/work/work.rlx: $(SRCS) $(HDRS)
	xvlog --relax --sv $(DEFINES) $(SRCS)

../fpga/ip:
	make -C ../fpga ip

xsim.dir/dram_mig/dram_mig.rlx: ../fpga/ip
	xvlog --relax --work dram_mig $(MIG_DIR)/dram_mig.v $(MIG_DIR)/dram_mig_mig_sim.v $(shell find $(MIG_DIR) -mindepth 2 -type f -name \*.v)

xsim.dir/glbl/glbl.rlx: $(XILINX_VIVADO)/data/verilog/src/glbl.v
	xvlog --relax --work glbl $(XILINX_VIVADO)/data/verilog/src/glbl.v

clean:
	-rm -r axsim.sh *.jou *.log *.pb *.vcd .hbs/ .Xil/ xsim.dir/
