read_verilog top_fpga.sv [glob ../src/*.sv]
synth_design -rtl -top top_fpga -part xc7s50csga324-1
