`timescale 1ns/1ps

`include "defines.svh"

module stage_mem(
  input logic         clk,
  input logic         reset_n,

  // inputs from execute stage
  input logic         mem_valid,
  input logic         mem_exc,
  input ecause_t      mem_exc_cause,

  input logic [31:2]  mem_pc,

  input logic [31:0]  mem_data0,
  input logic [31:0]  mem_data1,

  input logic         mem_read,
  input logic         mem_write,
  input logic         mem_extend,
  input logic [1:0]   mem_width,

  input logic [4:0]   wb_reg,

  // inputs from write stage
  input logic         wb_stall,

  // inputs/outputs to memory
  output logic        req,
  output logic [31:0] addr,
  output logic        write,
  output logic [31:0] data_out,
  output logic        extend,
  output logic [1:0]  width,
  input logic         ack,
  input logic         error,
  input logic [31:0]  data_in,

  // inputs/outputs to csr
  output logic [11:0] csr_addr,
  output logic [1:0]  csr_write,
  output logic [31:0] csr_data_out,
  input logic         csr_error,
  input logic [31:0]  csr_data_in,

  // outputs to execute stage
  output logic        mem_stall,

  // outputs to write stage
  output logic        wb_valid,
  output logic        wb_exc,
  output ecause_t     wb_exc_cause,

  output logic [31:2] wb_pc,

  output logic [4:0]  wb_reg_r,
  output logic [31:0] wb_data
  );

  assign
    req = mem_valid & (mem_read ^ mem_write) & ~wb_exc,
    addr = mem_data0,
    write = mem_write,
    data_out = mem_data1,
    extend = mem_extend,
    width = mem_width;

  logic csr_access, csr_read;
  assign csr_access = mem_read & mem_write;
  assign csr_read = csr_access & mem_extend;

  assign
    csr_addr = mem_data0[11:0],
    csr_write = csr_access ? mem_width : 0,
    csr_data_out = mem_data1;

  // When accessing from memory, assign the writeback data to the
  // value fetched from memory. Otherwise, just propagate the data
  // from execute through a register.
  logic exc;
  logic use_data_in;
  logic [31:0] reg_data;
  always_ff @(posedge clk) begin
    if(exc) begin
      reg_data <= mem_data0;
      use_data_in <= 1;
    end else begin
      reg_data <= csr_read ? csr_data_in : mem_data0;
      use_data_in <= mem_valid & mem_read & ~mem_write;
    end
  end

  assign wb_data = use_data_in ? data_in : reg_data;

  always_ff @(posedge clk) begin
    wb_pc <= mem_pc;
    wb_reg_r <= wb_reg;
  end

  ecause_t ecause;
  always_comb begin
    exc = 1;
    unique if(mem_exc)
      ecause = mem_exc_cause;
    else if(req) begin
      if((width[0] & addr[0]) | (width[1] & |addr[1:0]))
        ecause = mem_write ? SALIGN : LALIGN;
      else if(error)
        ecause = mem_write ? SFAULT : LFAULT;
      else
        exc = 0;
    end else
      exc = 0;
  end

  always_ff @(posedge clk)
    if(!wb_stall) begin
      wb_exc <= exc & ~wb_exc;
      wb_exc_cause <= ecause;
    end

  assign mem_stall = mem_valid & (wb_stall | (req & ~ack));
  always_ff @(posedge clk)
    if(~reset_n)
      wb_valid <= 0;
    else
      wb_valid <= wb_stall | (mem_valid & ~mem_stall & ~exc & ~wb_exc);

`ifndef SYNTHESIS
  always_ff @(posedge clk)
    if(mem_stall)
      $display("%d: stage_mem: stalling", $stime);
`endif

endmodule
