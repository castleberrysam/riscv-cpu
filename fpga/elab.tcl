read_verilog top_fpga.v [glob ../src/*.v]
synth_design -rtl -top top_fpga -part xc7s50csga324-1
