`timescale 1ns/1ps
`default_nettype none

module stage_write(
  input         clk,
  input         reset_n,

  // inputs from mem stage
  input         wb_valid,

  input [31:0]  wb_pc,

  input [4:0]   wb_reg,
  input [31:0]  wb_data,

  // outputs to decode stage
  output [4:0]  wreg,
  output [31:0] wdata,
  output        wen,

  // outputs to mem stage
  output        wb_stall
  );

    assign wreg = wb_reg;
    assign wdata = wb_data;
    assign wen = wb_valid;

    assign wb_stall = 0;

    reg [31:0] retire_pc;
    always @(posedge clk)
      if(wb_valid)
        begin
            retire_pc <= wb_pc;
            $strobe("%d: stage_write: retire insn at pc %08x", $stime, retire_pc);
        end

endmodule
