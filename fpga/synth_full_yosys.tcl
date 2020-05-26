read_edif top_fpga.edif
read_mem sram.mif
read_xdc constraints.xdc

link_design -top top_fpga -part xc7s50csga324-1
opt_design
place_design
phys_opt_design
route_design

report_timing_summary
report_utilization

write_bitstream -force top.bit
