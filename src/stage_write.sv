`timescale 1ns/1ps

`include "defines.svh"

module stage_write(
  input logic         clk_core,
  input logic         reset_n,

  // fetch1 inputs
  input logic         fe1_stall,

  // memory1 inputs/outputs
  input logic         mem1_valid_wb,
  output logic        wb_stall,
  input logic         mem1_exc,
  input ecause_t      mem1_exc_cause,
  input logic         mem1_flush,
  input logic [31:2]  mem1_pc,

  input logic         mem1_stall,

  input logic [4:0]   mem1_wb_reg,
  input logic [31:0]  mem1_dout,

  // decode outputs
  output logic        wb_valid,
  output logic [4:0]  wb_reg,
  output logic [31:0] wb_data,
  
  // csr outputs
  output logic        wb_exc,
  output ecause_t     wb_exc_cause,
  output logic        wb_flush,
  output logic [31:2] wb_pc
  );

  // we cannot interrupt an ongoing cache evict/fill (due to bus transactions)
  assign wb_stall = wb_exc & (fe1_stall | mem1_stall);

  always_ff @(posedge clk_core)
    if(~reset_n) begin
      wb_valid <= 0;
      wb_exc <= 0;
    end else if(~wb_stall) begin
      wb_valid <= mem1_valid_wb;
      wb_exc <= mem1_exc;
      wb_exc_cause <= mem1_exc_cause;
      wb_flush <= mem1_flush;
      wb_pc <= mem1_pc;

      wb_reg <= mem1_wb_reg;
      wb_data <= mem1_dout;
    end

`ifndef SYNTHESIS
  logic [31:0] retire_pc;
  always_ff @(posedge clk_core)
    if(wb_valid & ~wb_stall) begin
      retire_pc <= {wb_pc,2'b0};
      $strobe("%d: stage_write: retire insn at pc %08x", $stime, retire_pc);
    end

  always_ff @(posedge clk_core)
    if(wb_stall)
      $display("%d: stage_write: stalling", $stime);
`endif

endmodule
