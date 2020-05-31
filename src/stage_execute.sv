`timescale 1ns/1ps

module stage_execute(
  input logic         clk,
  input logic         reset_n,

  // inputs from decode stage
  input logic         ex_valid,

  input logic [31:0]  ex_pc,
  input logic [31:0]  ex_rdata1,
  input logic [31:0]  ex_rdata2,
  input logic [31:0]  ex_imm,

  input logic         ex_use_pc,
  input logic         ex_use_imm,
  input logic         ex_sub_sra,
  input logic [1:0]   ex_csr_write,
  input logic [3:0]   ex_op,

  input logic         ex_br,
  input logic         ex_br_inv,
  input logic         ex_br_taken,

  input logic         mem_read,
  input logic         mem_write,
  input logic         mem_extend,
  input logic [1:0]   mem_width,

  input logic [4:0]   wb_reg,

  // inputs from mem stage
  input logic         mem_stall,

  // inputs from write stage
  input logic         wb_valid,

  // outputs to decode stage
  output logic        ex_stall,
  output logic        ex_br_miss,

  // outputs to forwarding unit
  output logic [31:0] ex_forward_data,

  // outputs to mem stage
  output logic        mem_valid,

  output logic [31:0] mem_pc,

  output logic [31:0] mem_data0,
  output logic [31:0] mem_data1,

  output logic        mem_read_r,
  output logic        mem_write_r,
  output logic        mem_extend_r,
  output logic [1:0]  mem_width_r,

  output logic [4:0]  wb_reg_r
  );

`include "defines.vh"

  logic br_check;
  assign br_check = ex_valid & ~mem_stall & ex_br;
  assign ex_br_miss = br_check & (ex_br_inv ^ ex_br_taken ^ cmp_out);

  always_ff @(posedge clk)
    if(!mem_stall) begin
      mem_pc <= ex_pc;
      mem_read_r <= mem_read;
      mem_write_r <= mem_write;
      mem_extend_r <= mem_extend;
      mem_width_r <= mem_width;
      wb_reg_r <= wb_reg;
    end

  logic [31:0] op1, op2;
  assign op1 = ex_use_pc ? ex_pc : ex_rdata1;
  assign op2 = ex_use_imm ? ex_imm : ex_rdata2;

  logic mul_sign0, mul_sign1, mul_go;
  assign mul_sign0 = (ex_op == ALUOP_MUL) | (ex_op == ALUOP_MULH);
  assign mul_sign1 = mul_sign0 | (ex_op == ALUOP_MULHSU);
  assign mul_go = ex_valid & (mul_sign1 | (ex_op == ALUOP_MULHU));
  logic        mul_done;
  logic [63:0] mul_result;
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

  logic [31:0] csr_out;
  csr csr(
    .clk(clk),
    .reset_n(reset_n),

    .inc_instret(wb_valid),

    .addr(ex_imm[11:0]),
    .write(ex_csr_write),
    .data_in(ex_use_imm ? ex_imm : ex_rdata1),

    .data_out(csr_out)
    );

  logic cmp_out;
  always_comb
    case(ex_op)
      ALUOP_SEQ: cmp_out = ex_rdata1 == op2;
      ALUOP_SLT: cmp_out = $signed(ex_rdata1) < $signed(op2);
      ALUOP_SLTU: cmp_out = ex_rdata1 < op2;
      default: cmp_out = 0;
    endcase

  logic [31:0] alu_out;
  always_comb
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

      ALUOP_CSR: alu_out = csr_out;

      default: alu_out = 32'b0;
    endcase

  assign ex_forward_data = alu_out;

  always_ff @(posedge clk)
    if(!mem_stall) begin
      mem_data0 <= alu_out;
      mem_data1 <= ex_rdata2;
    end

  assign ex_stall = ex_valid & (mem_stall | (mul_go & ~mul_done));
  always_ff @(posedge clk)
    if(~reset_n)
      mem_valid <= 0;
    else
      mem_valid <= mem_stall | (ex_valid & ~ex_stall);

`ifndef SYNTHESIS
  always_ff @(posedge clk)
    if(ex_stall)
      $display("%d: stage_execute: stalling", $stime);
`endif

endmodule
