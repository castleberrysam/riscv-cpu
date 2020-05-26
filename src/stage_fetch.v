`timescale 1ns/1ps
`default_nettype none

module stage_fetch(
  input wire         clk,
  input wire         reset_n,

  // inputs from decode stage
  input wire         de_stall,

  input wire         de_setpc,
  input wire [31:0]  de_newpc,

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

    reg [31:0] fe_pc;
    always @(posedge clk)
      if(~reset_n)
        fe_pc <= 32'h80000000;
      else if(fe_ack & ~de_stall)
        fe_pc <= fe_addr + 4;

    assign fe_req = ~de_stall;
    assign fe_addr = de_setpc ? de_newpc : fe_pc;

    always @(posedge clk)
      if(~reset_n)
        de_valid <= 0;
      else if(fe_ack & ~de_stall)
        begin
            de_valid <= 1;
            de_pc <= fe_addr;
        end
      else
        de_valid <= de_stall;

endmodule
