`timescale 1ns/1ps
`default_nettype none

module stage_execute(
  input wire         clk,
  input wire         reset_n,

  // inputs from decode stage
  input wire         ex_valid,

  input wire [31:0]  ex_pc,
  input wire [31:0]  ex_rdata1,
  input wire [31:0]  ex_rdata2,
  input wire [31:0]  ex_imm,

  input wire         ex_use_pc,
  input wire         ex_use_imm,
  input wire         ex_sub_sra,
  input wire [3:0]   ex_op,

  input wire         ex_br,
  input wire         ex_br_inv,
  input wire         ex_br_taken,

  input wire         mem_read,
  input wire         mem_write,
  input wire         mem_extend,
  input wire [1:0]   mem_width,

  input wire [4:0]   wb_reg,

  // inputs from mem stage
  input wire         mem_stall,

  // outputs to decode stage
  output wire        ex_stall,

  output wire        ex_br_miss,

  // outputs to forwarding unit
  output wire [31:0] ex_forward_data,

  // outputs to mem stage
  output reg         mem_valid,

  output reg [31:0]  mem_pc,

  output reg [31:0]  mem_data0,
  output reg [31:0]  mem_data1,

  output reg         mem_read_r,
  output reg         mem_write_r,
  output reg         mem_extend_r,
  output reg [1:0]   mem_width_r,

  output reg [4:0]   wb_reg_r
  );

    `include "defines.vh"

    wire br_check = ex_valid & ~mem_stall & ex_br;
    assign ex_br_miss = br_check & (ex_br_inv ^ ex_br_taken ^ cmp_out);

    always @(posedge clk)
      if(!mem_stall)
        begin
            mem_pc <= ex_pc;
            mem_read_r <= mem_read;
            mem_write_r <= mem_write;
            mem_extend_r <= mem_extend;
            mem_width_r <= mem_width;
            wb_reg_r <= wb_reg;
        end

    wire [31:0] op1 = ex_use_pc ? ex_pc : ex_rdata1;
    wire [31:0] op2 = ex_use_imm ? ex_imm : ex_rdata2;

    wire mul_sign0 = (ex_op == ALUOP_MUL) | (ex_op == ALUOP_MULH);
    wire mul_sign1 = mul_sign0 | (ex_op == ALUOP_MULHSU);
    wire mul_go = ex_valid & (mul_sign1 | (ex_op == ALUOP_MULHU));
    wire mul_done;
    wire [63:0] mul_result;
    `ifndef SLOW_MUL
    mul_behav #(4) mul(
    `else
    mul_booth mul(
    `endif
      .clk(clk),
      .reset_n(reset_n),

      .go(mul_go),
      .sign0(mul_sign0),
      .sign1(mul_sign1),
      .m(op1),
      .r(op2),

      .done(mul_done),
      .result(mul_result)
      );

    reg cmp_out;
    always @(*)
      case(ex_op)
        ALUOP_SEQ: cmp_out = ex_rdata1 == op2;
        ALUOP_SLT: cmp_out = $signed(ex_rdata1) < $signed(op2);
        ALUOP_SLTU: cmp_out = ex_rdata1 < op2;
        default: cmp_out = 0;
      endcase

    reg [31:0] alu_out;
    always @(*)
      case(ex_op)
        ALUOP_NOP: alu_out = op2;

        ALUOP_ADD: alu_out = op1 + (ex_sub_sra ? -op2 : op2);
        ALUOP_AND: alu_out = op1 & op2;
        ALUOP_OR: alu_out = op1 | op2;
        ALUOP_XOR: alu_out = op1 ^ op2;

        ALUOP_SEQ, ALUOP_SLT, ALUOP_SLTU: alu_out = {31'd0,cmp_out};

        ALUOP_SL: alu_out = op1 << op2[4:0];
        ALUOP_SR: alu_out = ex_sub_sra ? (op1 >>> op2[4:0]) : (op1 >> op2[4:0]);

        ALUOP_MUL: alu_out = mul_result[31:0];
        ALUOP_MULH, ALUOP_MULHSU, ALUOP_MULHU: alu_out = mul_result[63:32];

        default: alu_out = 32'b0;
      endcase

    assign ex_forward_data = alu_out;

    always @(posedge clk)
      if(!mem_stall)
        begin
            mem_data0 <= alu_out;
            mem_data1 <= ex_rdata2;
        end

    assign ex_stall = ex_valid & (mem_stall | (mul_go & ~mul_done));
    always @(posedge clk)
      if(~reset_n)
        mem_valid <= 0;
      else
        mem_valid <= mem_stall | (ex_valid & ~ex_stall);

    `ifndef SYNTHESIS
    always @(posedge clk)
      if(ex_stall)
        $display("%d: stage_execute: stalling", $stime);
    `endif

endmodule
