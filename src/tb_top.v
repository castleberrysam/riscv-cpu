`timescale 1ns/1ps
`default_nettype none

module tb_top(
  );

    reg clk;
    reg reset_n;

    top uut(
      .clk(clk),
      .reset_n(reset_n)
      );

    initial
      begin
          $dumpfile("tb_top.vcd");
          $dumpvars;

          clk = 0;
          reset_n = 0;
          #10;
          reset_n = 1;
      end

    always
      #5 clk = ~clk;

    always @(uut.de_insn)
      if(uut.de_insn == 32'h00002013) // slti x0, x0, 0
        #50 $finish;

endmodule
