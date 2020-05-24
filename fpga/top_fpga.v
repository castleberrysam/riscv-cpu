`timescale 1ns/1ps
`default_nettype none

module top_fpga(
  input wire        CLK100MHZ,
  input wire [3:0]  btn,
  output wire [3:0] led
  );

    wire [31:0] fe_addr;
    top top(
      .clk(CLK100MHZ),
      .reset_n(~btn[0]),
      .fe_addr(fe_addr)
      );

    assign led = fe_addr[3:0];

endmodule
