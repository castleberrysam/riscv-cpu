`timescale 1ns/1ps

`include "defines.svh"

module stage_write(
  input logic         clk,
  input logic         reset_n,

  // inputs from mem stage
  input logic         wb_valid,
  input logic         wb_exc,

  input logic [31:2]  wb_pc,

  input logic [4:0]   wb_reg,
  input logic [31:0]  wb_data,

  // outputs to decode stage
  output logic [4:0]  wreg,
  output logic [31:0] wdata,
  output logic        wen,

  // outputs to mem stage
  output logic        wb_stall
  );

  assign wreg = wb_reg;
  assign wdata = wb_data;
  assign wen = wb_valid & ~wb_exc;

  assign wb_stall = 0;

`ifndef SYNTHESIS
  logic [31:0] retire_pc;
  always_ff @(posedge clk)
    if(wb_valid) begin
      retire_pc <= {wb_pc,2'b0};
      $strobe("%d: stage_write: retire insn at pc %08x", $stime, retire_pc);
    end

  always_ff @(posedge clk)
    if(wb_stall)
      $display("%d: stage_wb: stalling", $stime);
`endif

endmodule
