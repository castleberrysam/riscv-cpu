read_verilog top_fpga.v [glob ../src/*.v]
read_mem sram.mif
read_xdc constraints.xdc

synth_design -top top_fpga -part xc7s50csga324-1 -verilog_define XILINX
opt_design
place_design
phys_opt_design
route_design

report_timing
report_utilization

write_bitstream -force top.bit
