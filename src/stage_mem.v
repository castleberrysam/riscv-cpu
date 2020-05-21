`timescale 1ns/1ps
`default_nettype none

module stage_mem(
  input             clk,
  input             reset_n,

  // inputs from execute stage
  input             mem_valid,

  input [31:0]      mem_pc, 

  input [31:0]      mem_data0,
  input [31:0]      mem_data1,

  input             mem_read,
  input             mem_write,
  input             mem_extend,
  input [1:0]       mem_width,

  input             mem_jmp,
  input             mem_br,
  input             mem_br_inv,

  input [4:0]       wb_reg,

  // inputs from write stage
  input             wb_stall,

  // inputs/outputs to memory
  output            req,
  output [31:0]     addr,
  output            write,
  output [31:0]     data_out,
  output            extend,
  output [1:0]      width,
  input             ack,
  input [31:0]      data_in,

  // outputs to fetch stage
  output            fe_enable,
  output            pc_wen,
  output [31:0]     pc,

  // outputs to decode stage
  output [4:0]      wreg,
  output [31:0]     wdata,
  output            wen,

  // outputs to execute stage
  output            mem_stall,

  // outputs to write stage
  output reg        wb_valid,

  output reg [31:0] wb_pc,

  output reg [4:0]  wb_reg_r,
  output reg [31:0] wb_data
  );

    assign
      req = mem_valid & (mem_read | mem_write),
      addr = mem_data0,
      write = mem_write,
      data_out = mem_data1,
      extend = mem_extend,
      width = mem_width;

    assign
      fe_enable = mem_valid & (mem_jmp | mem_br),
      pc_wen = mem_valid & (mem_jmp | (mem_br & (mem_data0[0] ^ mem_br_inv))),
      pc = mem_data1;

    assign
      wreg = wb_reg,
      wdata = mem_data0,
      wen = mem_valid & (mem_jmp | ~req);

    always @(posedge clk)
      begin
          wb_pc <= mem_pc;
          wb_reg_r <= wb_reg;
          wb_data <= data_in;
      end

    reg [31:0] retire_pc;
    always @(posedge clk)
      if(wen)
        begin
            retire_pc <= mem_pc;
            $strobe("%d: stage_mem: retire insn at pc %08x", $stime, retire_pc);
        end

    assign mem_stall = mem_valid & (wb_stall | (req & ~ack));
    always @(posedge clk)
      if(~reset_n)
        wb_valid <= 0;
      else
        wb_valid <= wb_stall | (mem_valid & ~mem_stall & ~wen);

endmodule
