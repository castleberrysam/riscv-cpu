set_part xc7s50csga324-1

read_verilog top_fpga.sv [glob ../src/*.sv]
read_xdc constraints.xdc
read_ip ip/dram_mig/dram_mig.xci
read_mem rom.mif

synth_design -rtl -top top_fpga -verilog_define XILINX
