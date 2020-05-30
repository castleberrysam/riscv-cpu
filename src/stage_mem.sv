`timescale 1ns/1ps

module stage_mem(
  input logic         clk,
  input logic         reset_n,

  // inputs from execute stage
  input logic         mem_valid,

  input logic [31:0]  mem_pc,

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
  input logic [31:0]  data_in,

  // outputs to execute stage
  output logic        mem_stall,

  // outputs to write stage
  output logic        wb_valid,

  output logic [31:0] wb_pc,

  output logic [4:0]  wb_reg_r,
  output logic [31:0] wb_data
  );

  assign
    req = mem_valid & (mem_read | mem_write),
    addr = mem_data0,
    write = mem_write,
    data_out = mem_data1,
    extend = mem_extend,
    width = mem_width;

  // When accessing from memory, assign the writeback data to the
  // value fetched from memory. Otherwise, just propagate the data
  // from execute through a register.
  logic use_data_in;
  logic [31:0] reg_data;
  always_ff @(posedge clk) begin
    reg_data <= mem_data0;
    use_data_in <= (mem_valid & mem_read);
  end

  assign wb_data = use_data_in ? data_in : reg_data;

  always_ff @(posedge clk) begin
    wb_pc <= mem_pc;
    wb_reg_r <= wb_reg;
  end

  assign mem_stall = mem_valid & (wb_stall | (req & ~ack));
  always_ff @(posedge clk)
    if(~reset_n)
      wb_valid <= 0;
    else
      wb_valid <= wb_stall | (mem_valid & ~mem_stall) | (mem_valid & ~req);

`ifndef SYNTHESIS
  always_ff @(posedge clk)
    if(mem_stall)
      $display("%d: stage_mem: stalling", $stime);
`endif

endmodule
