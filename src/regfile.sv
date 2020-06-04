`timescale 1ns/1ps

`include "defines.svh"

module regfile(
  input logic         clk,
  input logic         reset_n,

  input logic [4:0]   rs1,
  output logic [31:0] rdata1,

  input logic [4:0]   rs2,
  output logic [31:0] rdata2,

  input logic [4:0]   wreg,
  input logic [31:0]  wdata,
  input logic         wen
  );

  logic [31:0] regs[31:1];

  // read port 1 (with passthrough)
  logic wr_rs1;
  assign wr_rs1 = wen & (wreg == rs1);
  always_comb
    if(~|rs1)
      rdata1 = 0;
    else if(wr_rs1)
      rdata1 = wdata;
    else
      rdata1 = regs[rs1];

  // read port 2 (with passthrough)
  logic wr_rs2;
  assign wr_rs2 = wen & (wreg == rs2);
  always_comb
    if(~|rs2)
      rdata2 = 0;
    else if(wr_rs2)
      rdata2 = wdata;
    else
      rdata2 = regs[rs2];

`ifndef SYNTHESIS
  always_ff @(posedge clk)
    if(wen && |wreg)
      $display("%d: regfile: write %0s (x%0d) = %08x", $stime, abi_names[wreg], wreg, wdata);
`endif

  always_ff @(posedge clk)
    if(~reset_n)
      for(int i=1;i<32;i++)
        regs[i] <= 0;
    else if(wen && |wreg)
      regs[wreg] <= wdata;

endmodule
