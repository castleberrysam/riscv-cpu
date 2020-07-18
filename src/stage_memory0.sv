`timescale 1ns/1ps

`include "defines.svh"

module stage_memory0(
  input logic         clk_core,
  input logic         reset_n,

  // execute inputs/outputs
  input logic         ex_valid,
  input logic         ex_stall,
  output logic        mem0_stall,
  input logic         ex_exc,
  input ecause_t      ex_exc_cause,
  input logic [31:2]  ex_pc,

  input logic [31:0]  ex_data0,
  input logic [31:0]  ex_data1,

  input logic         ex_mem_read,
  input logic         ex_mem_write,
  input logic         ex_mem_extend,
  input logic [1:0]   ex_mem_width,

  input logic [4:0]   ex_wb_reg,

  // fetch1 inputs
  input logic         fe1_mem0_read,
  input logic [28:2]  fe1_mem0_addr,

  // decode outputs
  output logic        mem0_fwd_valid,
  output logic        mem0_fwd_stall,
  output logic [31:0] mem0_fwd_data,

  // dcache outputs
  output logic        mem0_dc_read,
  output logic        mem0_dc_trans,
  output logic [8:0]  mem0_dc_asid,
  output logic [31:2] mem0_dc_addr,

  // csr inputs
  input logic         csr_kill,

  input logic [31:0]  csr_satp,

  // memory1 inputs/outputs
  output logic        mem0_valid,
  input logic         mem1_stall,
  output logic        mem0_exc,
  output ecause_t     mem0_exc_cause,
  output logic [31:2] mem0_pc,

  output logic        mem0_mem1_req,
  output logic        mem0_fe1_req,

  output logic        mem0_read,
  output logic        mem0_write,
  output logic        mem0_extend,
  output logic [1:0]  mem0_width,
  output logic [31:0] mem0_addr,
  output logic [31:0] mem0_wdata,

  output logic [4:0]  mem0_wb_reg,

  input logic         mem1_mem0_read,
  input logic         mem1_mem0_trans,
  input logic [31:2]  mem1_mem0_addr
  );

  logic         satp_mode;
  logic [8:0]   satp_asid;
  logic [28:12] satp_ppn;
  assign satp_mode = csr_satp[31];
  assign satp_asid = csr_satp[30:22];
  assign satp_ppn  = csr_satp[16:0];

  assign mem0_dc_asid = satp_asid;

  logic valid, exc;
  logic [31:0] ex_data0_r;
  always_ff @(posedge clk_core)
    if(~reset_n) begin
      valid <= 0;
      exc <= 0;
    end else if(~mem0_stall | csr_kill) begin
      valid <= ex_valid;
      exc <= ex_exc;
      mem0_exc_cause <= ex_exc_cause;
      mem0_pc <= ex_pc;

      mem0_read <= ex_mem_read;
      mem0_write <= ex_mem_write;
      mem0_extend <= ex_mem_extend;
      mem0_width <= ex_mem_width;
      ex_data0_r <= ex_data0;
      mem0_wdata <= ex_data1;

      mem0_wb_reg <= ex_wb_reg;
    end

  assign mem0_valid = ((valid & ~mem0_stall & ~exc) | fe1_mem0_read) & ~csr_kill;
  assign mem0_exc = exc & ~fe1_mem0_read & ~csr_kill;

  assign mem0_mem1_req = mem1_mem0_read; 
  assign mem0_fe1_req = fe1_mem0_read;

  assign mem0_fwd_valid = valid;
  assign mem0_fwd_stall = mem0_read;
  assign mem0_fwd_data = ex_data0_r;

  always_comb begin
    mem0_dc_read = 0;
    mem0_dc_trans = 0;
    mem0_dc_addr = '0;
    mem0_addr = ex_data0_r;

    if(mem1_mem0_read) begin
      mem0_dc_read = 1;
      mem0_dc_trans = mem1_mem0_trans;
      mem0_dc_addr = mem1_mem0_addr;
      mem0_addr = {mem0_dc_addr,2'b0};
    end else if(fe1_mem0_read) begin
      mem0_dc_read = 1;
      mem0_dc_addr = {3'b0,fe1_mem0_addr};
      mem0_addr = {mem0_dc_addr,2'b0};
    end else if(valid) begin
      mem0_dc_read = ~mem0_stall & (mem0_read | mem0_write);
      mem0_dc_trans = 1;
      mem0_dc_addr = ex_data0_r[31:2];
    end
  end

  assign mem0_stall = (valid | exc) & (mem1_stall | fe1_mem0_read);

endmodule
