`timescale 1ns/1ps

`include "defines.svh"

module stage_write(
  input logic         clk_core,
  input logic         reset_n,

  // memory1 inputs/outputs
  input logic         mem1_valid_wb,
  input logic         mem1_stall,
  output logic        wb_stall,
  input logic         mem1_exc,
  input ecause_t      mem1_exc_cause,
  input logic         mem1_flush,
  input logic [31:2]  mem1_pc,

  input logic [4:0]   mem1_wb_reg,
  input logic [31:0]  mem1_dout,

  // decode outputs
  output logic [4:0]  wb_reg,
  output logic [31:0] wb_data,
  
  // csr inputs/outputs
  input logic         csr_kill,

  output logic        wb_valid,
  output logic        wb_exc,
  output ecause_t     wb_exc_cause,
  output logic        wb_flush,
  output logic [31:2] wb_pc
  );

  logic wb_flush_r;
  always_ff @(posedge clk_core)
    wb_flush_r <= wb_flush;

  assign wb_stall = wb_valid & wb_flush & ~wb_flush_r;

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
  logic test_stop;
  assign test_stop = wb_exc & (wb_exc_cause == IILLEGAL) & (wb_data == TEST_MAGIC);

  always_ff @(negedge clk_core)
    if(wb_valid) begin
      if(~wb_stall)
        $strobe("%d: stage_write: retire insn at pc %8x", $stime, {wb_pc,2'b0});
    end else if(wb_exc)
      $strobe("%d: stage_write: take exception at pc %8x", $stime, {wb_pc,2'b0});
`endif

endmodule
