`timescale 1ns/1ps

`include "defines.svh"

module stage_execute(
  input logic         clk_core,
  input logic         reset_n,

  // fetch1 outputs
  output logic        ex_specid,
  output logic        ex_br_ntaken,
  output logic        ex_br_taken,

  // decode inputs/outputs
  input logic         de_valid,
  input logic         de_stall,
  output logic        ex_stall,
  input logic         de_exc,
  input ecause_t      de_exc_cause,
  input logic [31:2]  de_pc,

  input logic         de_specid,

  input logic [31:0]  de_rdata1,
  input logic [31:0]  de_rdata2,
  input logic [31:0]  de_imm,

  input logic         de_use_pc,
  input logic         de_use_imm,
  input logic         de_sub_sra,
  input logic         de_data1_sel,
  input aluop_t       de_op,

  input logic         de_br,
  input logic         de_br_inv,
  input logic         de_br_pred,
  input logic         de_jump,

  input logic         de_br_misalign,
  input logic         de_br_miss_misalign,

  input logic         de_mem_read,
  input logic         de_mem_write,
  input logic         de_mem_extend,
  input logic [1:0]   de_mem_width,

  input logic [4:0]   de_wb_reg,

  output logic        ex_br_miss,

  // memory0 inputs/outputs
  output logic        ex_valid,
  input logic         mem0_stall,
  output logic        ex_exc,
  output ecause_t     ex_exc_cause,
  output logic [31:2] ex_pc,

  output logic [31:0] ex_data0,
  output logic [31:0] ex_data1,

  output logic        ex_mem_read,
  output logic        ex_mem_write,
  output logic        ex_mem_extend,
  output logic [1:0]  ex_mem_width,

  output logic [4:0]  ex_wb_reg,

  // csr inputs
  input logic         csr_kill,

  // writeback inputs
  input logic         wb_exc,

  // forward unit outputs
  output logic        ex_fwd_valid,
  output logic        ex_fwd_stall,
  output logic [31:0] ex_fwd_data
  );

  logic        de_exc_r;
  ecause_t     de_exc_cause_r;

  logic        valid;
  logic [31:0] ex_rdata1, ex_rdata2, ex_imm;
  logic        ex_use_pc, ex_use_imm, ex_sub_sra, ex_data1_sel;
  aluop_t      ex_op;
  logic        ex_br, ex_br_inv, ex_br_pred, ex_jump;
  logic        ex_br_misalign, ex_br_miss_misalign;
  always_ff @(posedge clk_core)
    if(~reset_n) begin
      valid <= 0;
      de_exc_r <= 0;
    end else if(~ex_stall | csr_kill) begin
      valid <= de_valid;
      de_exc_r <= de_exc;
      de_exc_cause_r <= de_exc_cause;
      ex_pc <= de_pc;

      ex_specid <= de_specid;

      ex_rdata1 <= de_rdata1;
      ex_rdata2 <= de_rdata2;
      ex_imm <= de_imm;

      ex_use_pc <= de_use_pc;
      ex_use_imm <= de_use_imm;
      ex_sub_sra <= de_sub_sra;
      ex_data1_sel <= de_data1_sel;
      ex_op <= de_op;

      ex_br <= de_br;
      ex_br_inv <= de_br_inv;
      ex_br_pred <= de_br_pred;
      ex_jump <= de_jump;

      ex_br_misalign <= de_br_misalign;
      ex_br_miss_misalign <= de_br_miss_misalign;

      ex_mem_read <= de_mem_read;
      ex_mem_write <= de_mem_write;
      ex_mem_extend <= de_mem_extend;
      ex_mem_width <= de_mem_width;

      ex_wb_reg  <= de_wb_reg;
    end

  assign ex_valid = valid & ~ex_stall & ~exc & ~csr_kill;
  assign ex_exc = exc & ~csr_kill;

  logic br_cond, br_miss, br_ntaken, br_taken;
  assign br_cond = ex_br_inv ^ cmp_out;
  assign br_miss = valid & ex_br & (ex_br_pred ^ br_cond);
  assign br_ntaken = valid & ex_br & ~br_cond;
  assign br_taken = valid & (ex_jump | (ex_br & br_cond));

  logic br_miss_r, br_ntaken_r, br_taken_r;
  always_ff @(posedge clk_core)
    if(~ex_stall | csr_kill) begin
      br_miss_r <= 0;
      br_ntaken_r <= 0;
      br_taken_r <= 0;
    end else begin
      br_miss_r <= br_miss;
      br_ntaken_r <= br_ntaken;
      br_taken_r <= br_taken;
    end

  assign ex_br_miss = br_miss & ~br_miss_r;
  assign ex_br_ntaken = br_ntaken & ~br_ntaken_r;
  assign ex_br_taken = br_taken & ~br_taken_r;

  logic [31:0] op1, op2;
  assign op1 = ex_use_pc ? {ex_pc,2'b0} : ex_rdata1;
  assign op2 = ex_use_imm ? ex_imm : ex_rdata2;

  logic mul_sign0, mul_sign1, mul_go;
  assign mul_sign0 = ex_op.mul | ex_op.mulh;
  assign mul_sign1 = mul_sign0 | ex_op.mulhsu;
  assign mul_go = valid & (mul_sign1 | ex_op.mulhu);
  logic        mul_done;
  logic [63:0] mul_result;
  mul_behav #(4) mul(
    .clk(clk_core),
    .reset_n(reset_n),

    .go(mul_go),
    .sign0(mul_sign0),
    .sign1(mul_sign1),
    .m(op1),
    .r(op2),

    .done(mul_done),
    .result(mul_result)
    );

  logic cmp_out;
  always_comb
    unique case(1)
      ex_op.seq: cmp_out = ex_rdata1 == op2;
      ex_op.slt: cmp_out = $signed(ex_rdata1) < $signed(op2);
      ex_op.sltu: cmp_out = ex_rdata1 < op2;
      default: cmp_out = '0;
    endcase

  logic [31:0] alu_out;
  always_comb
    unique case(1)
      ex_op.nop: alu_out = op2;

      ex_op.add: alu_out = op1 + (ex_sub_sra ? -op2 : op2);
      ex_op.and_: alu_out = op1 & op2;
      ex_op.or_: alu_out = op1 | op2;
      ex_op.xor_: alu_out = op1 ^ op2;

      ex_op.seq, ex_op.slt, ex_op.sltu: alu_out = {31'd0,cmp_out};

      ex_op.sl: alu_out = op1 << op2[4:0];
      ex_op.sr: alu_out = ex_sub_sra ? (op1 >>> op2[4:0]) : (op1 >> op2[4:0]);

      ex_op.mul: alu_out = mul_result[31:0];
      ex_op.mulh, ex_op.mulhsu, ex_op.mulhu: alu_out = mul_result[63:32];

      default: alu_out = '0;
    endcase

  assign ex_fwd_valid = valid;
  assign ex_fwd_stall = ex_mem_read | mul_stall;
  assign ex_fwd_data = alu_out;

  always_comb begin
    ex_data0 = ex_exc ? ex_imm : alu_out;
    ex_data1 = ex_data1_sel ? ex_rdata1 : ex_rdata2;
  end

  logic exc;
  always_comb begin
    exc = de_exc_r;
    ex_exc_cause = de_exc_cause_r;
    if(valid) begin
      exc = 1;
      if(ex_br & ex_br_miss & ex_br_misalign)
        ex_exc_cause = IALIGN;
      else if(ex_br & ~ex_br_miss & ex_br_miss_misalign)
        ex_exc_cause = IALIGN;
      else
        exc = 0;
    end
  end

  logic mul_stall;
  assign mul_stall = mul_go & ~mul_done;

  assign ex_stall = (valid & (mem0_stall | mul_stall)) | (exc & mem0_stall);

endmodule
