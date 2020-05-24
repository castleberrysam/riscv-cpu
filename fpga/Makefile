SRCS := top_fpga.v $(wildcard ../src/*.v)

.PHONY: all yosys prog flash clean

all: top.bit

top.bit: $(SRCS) sram.mif constraints.xdc synth.tcl
	vivado -nojou -mode batch -source synth.tcl

yosys: top_yosys.bit

top_yosys.bit: top_fpga.edif sram.mif constraints.xdc synth_yosys.tcl
	vivado -nojou -mode batch -source synth_yosys.tcl

top_fpga.edif: $(SRCS)
	yosys -DSLOW_MUL -p 'synth_xilinx -top top_fpga; write_edif -top top_fpga top_fpga.edif' $(SRCS)

%.mif: %.bin bin2mif.py
	./bin2mif.py $< 16384 > $@

%.bin: %.o
	riscv64-linux-gnu-objcopy -O binary $< $@

%.o: %.s
	riscv64-linux-gnu-as -march=rv32im -o $@ $<

clean:
	-rm -r *.bit *.mcs *.prm *.jou *.log *.html *.xml *.str .Xil/

prog: top.bit prog_fpga.tcl
	vivado -nojou -mode batch -source prog_fpga.tcl

flash: top.mcs top.prm prog_flash.tcl
	vivado -nojou -mode batch -source prog_flash.tcl

top.mcs top.prm &: top.bit gen_mcs.tcl
	vivado -nojou -mode batch -source gen_mcs.tcl
