`timescale 1ns/1ps

`include "defines.svh"

module stage_fetch0(
  input logic         clk_core,
  input logic         reset_n,

  // fetch1 inputs/outputs
  output logic        fe0_valid,
  input logic         fe1_stall,

  output logic        fe0_speculative,

  // icache outputs
  output logic        fe0_read_req,
  output logic [8:0]  fe0_read_asid,
  output logic [31:2] fe0_read_addr,

  // decode inputs
  input logic         de_setpc,
  input logic         de_speculative,
  input logic [31:2]  de_newpc,

  // csr inputs
  input logic         csr_fe_inhibit,
  input logic         csr_setpc,
  input logic [31:2]  csr_newpc,

  input logic [31:0]  csr_satp
  );

  assign fe0_valid = fe0_read_req;

  logic [31:0] fe0_pc;
  always_ff @(posedge clk_core)
    if(~reset_n)
      fe0_pc <= '0;
    else if(fe0_read_req | csr_fe_inhibit)
      fe0_pc <= fe0_read_addr + 1;
    else if(csr_setpc | de_setpc)
      fe0_pc <= fe0_read_addr;

  assign fe0_read_asid = csr_satp[30:22];

  always_comb begin
    fe0_read_req = ~fe1_stall & ~csr_fe_inhibit;
    if(csr_setpc)
      fe0_read_addr = csr_newpc;
    else if(de_setpc)
      fe0_read_addr = de_newpc;
    else
      fe0_read_addr = fe0_pc;
  end

  logic speculative;
  always_ff @(posedge clk_core)
    if(~reset_n)
      speculative <= 0;
    else if(csr_setpc)
      speculative <= 0;
    else if(de_setpc & ~fe0_read_req)
      speculative <= de_speculative;
    else if(fe0_read_req)
      speculative <= 0;

  assign fe0_speculative = speculative | (~csr_setpc & de_setpc & de_speculative);

endmodule
