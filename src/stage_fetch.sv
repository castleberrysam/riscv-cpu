`timescale 1ns/1ps

module stage_fetch(
  input logic         clk,
  input logic         reset_n,

  // inputs from decode stage
  input logic         de_stall,
  input logic         de_setpc,
  input logic [31:0]  de_newpc,

  // inputs/outputs to memory
  output logic        fe_req,
  output logic [31:0] fe_addr,
  input logic         fe_ack,
  input logic [31:0]  fe_data,

  // outputs to decode stage
  output logic        de_valid,
  output logic [31:0] de_pc,
  output logic [31:0] de_insn
  );

  assign de_insn = fe_data;

  logic [31:0] fe_pc;
  always_ff @(posedge clk)
    if(~reset_n)
      fe_pc <= 32'h80000000;
    else if(fe_ack & ~de_stall)
      fe_pc <= fe_addr + 4;

  assign fe_req = ~de_stall;
  assign fe_addr = de_setpc ? de_newpc : fe_pc;

  always_ff @(posedge clk)
    if(~reset_n)
      de_valid <= 0;
    else if(fe_ack & ~de_stall) begin
      de_valid <= 1;
      de_pc <= fe_addr;
    end else
      de_valid <= de_stall;

endmodule
