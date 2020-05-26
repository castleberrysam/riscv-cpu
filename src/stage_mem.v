`timescale 1ns/1ps
`default_nettype none

module stage_mem(
  input wire         clk,
  input wire         reset_n,

  // inputs from execute stage
  input wire         mem_valid,

  input wire [31:0]  mem_pc, 

  input wire [31:0]  mem_data0,
  input wire [31:0]  mem_data1,

  input wire         mem_read,
  input wire         mem_write,
  input wire         mem_extend,
  input wire [1:0]   mem_width,

  input wire [4:0]   wb_reg,

  // inputs from write stage
  input wire         wb_stall,

  // inputs/outputs to memory
  output wire        req,
  output wire [31:0] addr,
  output wire        write,
  output wire [31:0] data_out,
  output wire        extend,
  output wire [1:0]  width,
  input wire         ack,
  input wire [31:0]  data_in,

  // outputs to execute stage
  output wire        mem_stall,

  // outputs to write stage
  output reg         wb_valid,

  output reg [31:0]  wb_pc,

  output reg [4:0]   wb_reg_r,
  output wire [31:0] wb_data
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
    reg use_data_in;
    reg [31:0] reg_data;
    always @(posedge clk)
      begin
         reg_data <= mem_data0;
         use_data_in <= (mem_valid & mem_read);
      end

    assign wb_data = use_data_in ? data_in : reg_data;

    always @(posedge clk)
      begin
          wb_pc <= mem_pc;
          wb_reg_r <= wb_reg;
      end

    assign mem_stall = mem_valid & (wb_stall | (req & ~ack));
    always @(posedge clk)
      if(~reset_n)
        wb_valid <= 0;
      else
        wb_valid <= wb_stall | (mem_valid & ~mem_stall) | (mem_valid & ~req);

    `ifndef SYNTHESIS
    always @(posedge clk)
      if(mem_stall)
        $display("%d: stage_mem: stalling", $stime);
    `endif

endmodule
