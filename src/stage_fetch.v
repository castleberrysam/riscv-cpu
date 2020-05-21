`timescale 1ns/1ps
`default_nettype none

module stage_fetch(
  input             clk,
  input             reset_n,

  // inputs from decode stage
  input             de_stall,

  // inputs from mem stage
  input             fe_enable,
  input             pc_wen,
  input [31:0]      pc_in,

  // inputs/outputs to memory
  output            req,
  output [31:0]     addr,
  input             ack,
  input [31:0]      data,

  // outputs to decode stage
  output reg        de_valid,
  output reg [31:0] de_insn,
  output reg [31:0] de_pc
  );

    reg [31:0] pc;
    reg        pc_valid;

    assign req = pc_valid;
    assign addr = pc;

    wire [4:0] opcode = data[6:2];
    always @(posedge clk)
      if(~reset_n)
        begin
            de_valid <= 0;
            pc <= 32'h80000000;
            pc_valid <= 1;
        end
      else if(fe_enable)
        begin
            //$display("%d: stage_fetch: write pc = %08x", $stime, pc_in);
            de_valid <= de_stall;
            if(pc_wen)
              pc <= pc_in;
            pc_valid <= 1;
        end
      else if(ack & ~de_stall)
        begin
            //$display("%d: stage_fetch: fetch insn %08x at pc %08x", $stime, data, pc);
            de_valid <= 1;
            de_insn <= data;
            de_pc <= pc;
            pc <= pc + 4;
            pc_valid <= ~data[6];
        end
      else
        de_valid <= de_stall;

endmodule
