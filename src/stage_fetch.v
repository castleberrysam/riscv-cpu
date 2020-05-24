`timescale 1ns/1ps
`default_nettype none

module stage_fetch(
  input wire         clk,
  input wire         reset_n,

  // inputs from decode stage
  input wire         de_stall,

  // inputs from mem stage
  input wire         fe_enable,
  input wire         pc_wen,
  input wire [31:0]  pc_in,

  // inputs/outputs to memory
  output wire        fe_req,
  output wire [31:0] fe_addr,
  input wire         fe_ack,
  input wire [31:0]  fe_data,

  // outputs to decode stage
  output reg         de_valid,
  output wire [31:0] de_insn,
  output reg [31:0]  de_pc
  );

    assign de_insn = fe_data;
    wire fe_stall = fe_data[6];

    reg [31:0] pc;
    wire [31:0] cur_pc = pc_wen ? pc_in : pc;

    assign fe_req = (~fe_stall | fe_enable) & ~de_stall;
    assign fe_addr = cur_pc;

    always @(posedge clk)
      if(~reset_n)
        pc <= 32'h80000000;
      else if(fe_ack)
        pc <= cur_pc + 4;

    always @(posedge clk)
      if(~reset_n)
        de_valid <= 0;
      else if(fe_ack & ~de_stall)
        begin
            de_valid <= 1;
            de_pc <= cur_pc;
        end
      else
        de_valid <= de_stall;

    `ifndef SYNTHESIS
    always @(posedge clk)
      if(fe_stall)
        $display("%d: stage_fetch: stalling", $stime);
    `endif

endmodule
