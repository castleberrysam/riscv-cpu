`timescale 1ns/1ps
`default_nettype none

module regfile(
  input wire        clk,
  input wire        reset_n,

  input wire [4:0]  rs1,
  output reg [31:0] rdata1,

  input wire [4:0]  rs2,
  output reg [31:0] rdata2,

  input wire [4:0]  wreg,
  input wire [31:0] wdata,
  input wire        wen
  );

    `include "defines.vh"

    reg [31:0] regs[31:1];

    // read port 1 (with passthrough)
    wire wr_rs1 = wen & (wreg == rs1);
    always @(*)
      if(~|rs1)
        rdata1 = 32'b0;
      else if(wr_rs1)
        rdata1 = wdata;
      else
        rdata1 = regs[rs1];

    // read port 2 (with passthrough)
    wire wr_rs2 = wen & (wreg == rs2);
    always @(*)
      if(~|rs2)
        rdata2 = 32'b0;
      else if(wr_rs2)
        rdata2 = wdata;
      else
        rdata2 = regs[rs2];

    `ifndef SYNTHESIS
    always @(posedge clk)
      if(wen && |wreg)
        $display("%d: regfile: write %0s (x%0d) = %08x", $stime, abi_name(wreg), wreg, wdata);
    `endif

    integer i;
    always @(posedge clk)
      if(~reset_n)
        for(i=1;i<32;i=i+1)
          regs[i] <= 32'b0;
      else if(wen && |wreg)
        regs[wreg] <= wdata;

endmodule
