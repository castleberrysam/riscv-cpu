`timescale 1ns/1ps
`default_nettype none

module stage_write(
  input wire         clk,
  input wire         reset_n,

  // inputs from mem stage
  input wire         wb_valid,

  input wire [31:0]  wb_pc,

  input wire [4:0]   wb_reg,
  input wire [31:0]  wb_data,

  // outputs to decode stage
  output wire [4:0]  wreg,
  output wire [31:0] wdata,
  output wire        wen,

  // outputs to mem stage
  output wire        wb_stall
  );

    assign wreg = wb_reg;
    assign wdata = wb_data;
    assign wen = wb_valid;

    assign wb_stall = 0;

    `ifndef SYNTHESIS
    reg [31:0] retire_pc;
    always @(posedge clk)
      if(wb_valid)
        begin
            retire_pc <= wb_pc;
            $strobe("%d: stage_write: retire insn at pc %08x", $stime, retire_pc);
        end
    `endif

    `ifndef SYNTHESIS
    always @(posedge clk)
      if(wb_stall)
        $display("%d: stage_wb: stalling", $stime);
    `endif

endmodule
