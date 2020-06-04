`timescale 1ns/1ps

`include "defines.svh"

module stage_fetch(
  input logic         clk,
  input logic         reset_n,

  // inputs from decode stage
  input logic         de_stall,
  input logic         de_setpc,
  input logic [31:2]  de_newpc,

  // inputs from csr unit
  input logic         csr_setpc,
  input logic [31:2]  csr_newpc,

  // inputs/outputs to memory
  output logic        fe_req,
  output logic [31:2] fe_addr,
  input logic         fe_ack,
  input logic         fe_error,
  input logic [31:0]  fe_data,

  // outputs to decode stage
  output logic        de_valid,
  output logic        de_exc,
  output logic [31:2] de_pc,
  output logic [31:0] de_insn
  );

  assign de_insn = fe_data;

  logic [31:2] fe_pc;
  always_ff @(posedge clk)
    if(~reset_n)
      // byte address 80000000
      fe_pc <= 'h20000000;
    else if(fe_req & fe_ack)
      fe_pc <= fe_addr + 1;

  always_comb begin
    fe_req = ~de_stall | csr_setpc;
    if(csr_setpc)
      fe_addr = csr_newpc;
    else if(de_setpc)
      fe_addr = de_newpc;
    else
      fe_addr = fe_pc;
  end

  always_ff @(posedge clk)
    if(~reset_n)
      de_valid <= 0;
    else if(fe_req & fe_ack) begin
      de_valid <= ~fe_error;
      de_exc <= fe_error;
      de_pc <= fe_addr;
    end else
      de_valid <= de_stall;

endmodule
