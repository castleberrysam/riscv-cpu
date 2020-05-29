SRCS := top_fpga.v $(wildcard ../src/*.v)

.PHONY: all elab timing yosys prog flash clean

all: top.bit

top.bit: $(SRCS) sram.mif constraints.xdc synth_full.tcl
	vivado -nojou -mode batch -source synth_full.tcl

elab: $(SRCS) elab.tcl
	vivado -nojou -mode tcl -source elab.tcl

timing: $(SRCS) sram.mif constraints.xdc synth_timing.tcl
	vivado -nojou -mode batch -source synth_timing.tcl

yosys: top_yosys.bit

top_yosys.bit: top_fpga.edif sram.mif constraints.xdc synth_full_yosys.tcl
	vivado -nojou -mode batch -source synth_full_yosys.tcl

top_fpga.edif: $(SRCS)
	yosys -DSLOW_MUL -p 'synth_xilinx -top top_fpga; write_edif -top top_fpga top_fpga.edif' $(SRCS)

%.mif: %.bin bin2mif.py
	./bin2mif.py $< 16384 > $@

%.bin: %.o
	riscv64-linux-gnu-objcopy -O binary $< $@

%.o: %.s
	riscv64-linux-gnu-as -march=rv32im -o $@ $<

prog: top.bit prog_fpga.tcl
	vivado -nojou -mode batch -source prog_fpga.tcl

flash: top.mcs top.prm prog_flash.tcl
	vivado -nojou -mode batch -source prog_flash.tcl

top.mcs top.prm &: top.bit gen_mcs.tcl
	vivado -nojou -mode batch -source gen_mcs.tcl

clean:
	-rm -r *.o *.bin *.mif *.bit *.edif *.mcs *.prm *.jou *.log *.html *.xml *.str .Xil/
