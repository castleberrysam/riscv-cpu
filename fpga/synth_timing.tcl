read_verilog top_fpga.sv [glob ../src/*.sv]
read_mem sram.mif
read_xdc constraints.xdc

synth_design -top top_fpga -part xc7s50csga324-1 -verilog_define XILINX -flatten_hierarchy none
opt_design

report_timing
