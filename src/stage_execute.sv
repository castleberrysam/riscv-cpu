`timescale 1ns/1ps

`include "defines.svh"

module stage_execute(
  input logic         clk,
  input logic         reset_n,

  // inputs from decode stage
  input logic         ex_valid,
  input logic         ex_exc,
  input ecause_t      ex_exc_cause,

  input logic [31:2]  ex_pc,
  input logic [31:0]  ex_rdata1,
  input logic [31:0]  ex_rdata2,
  input logic [31:0]  ex_imm,

  input logic         ex_use_pc,
  input logic         ex_use_imm,
  input logic         ex_sub_sra,
  input logic         ex_data1_sel,
  input aluop_t       ex_op,

  input logic         ex_br,
  input logic         ex_br_inv,
  input logic         ex_br_taken,

  input logic         ex_br_misalign,
  input logic         ex_br_miss_misalign,

  input logic         mem_read,
  input logic         mem_write,
  input logic         mem_extend,
  input logic [1:0]   mem_width,

  input logic [4:0]   wb_reg,

  // inputs from mem stage
  input logic         mem_stall,

  // inputs from write stage
  input logic         wb_exc,

  // outputs to decode stage
  output logic        ex_stall,
  output logic        ex_br_miss,

  // outputs to forwarding unit
  output logic [31:0] ex_forward_data,

  // outputs to mem stage
  output logic        mem_valid,
  output logic        mem_exc,
  output ecause_t     mem_exc_cause,

  output logic [31:2] mem_pc,

  output logic [31:0] mem_data0,
  output logic [31:0] mem_data1,

  output logic        mem_read_r,
  output logic        mem_write_r,
  output logic        mem_extend_r,
  output logic [1:0]  mem_width_r,

  output logic [4:0]  wb_reg_r
  );

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
  assign op1 = ex_use_pc ? {ex_pc,2'b0} : ex_rdata1;
  assign op2 = ex_use_imm ? ex_imm : ex_rdata2;

  logic mul_sign0, mul_sign1, mul_go;
  assign mul_sign0 = ex_op.mul | ex_op.mulh;
  assign mul_sign1 = mul_sign0 | ex_op.mulhsu;
  assign mul_go = ex_valid & (mul_sign1 | ex_op.mulhu);
  logic        mul_done;
  logic [63:0] mul_result;
  mul_behav #(4) mul(
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

  logic cmp_out;
  always_comb
    unique0 case(1)
      ex_op.seq: cmp_out = ex_rdata1 == op2;
      ex_op.slt: cmp_out = $signed(ex_rdata1) < $signed(op2);
      ex_op.sltu: cmp_out = ex_rdata1 < op2;
    endcase

  logic [31:0] alu_out;
  always_comb
    unique0 case(1)
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
    endcase

  assign ex_forward_data = alu_out;

  logic exc;
  always_ff @(posedge clk)
    if(!mem_stall) begin
      mem_data0 <= exc ? ex_imm : alu_out;
      mem_data1 <= ex_data1_sel ? ex_rdata1 : ex_rdata2;
    end

  ecause_t ecause;
  always_comb begin
    exc = 1;
    unique if(ex_exc)
      ecause = ex_exc_cause;
    else if(ex_valid & ex_br & ex_br_miss & ex_br_misalign)
      ecause = IALIGN;
    else if(ex_valid & ex_br & ~ex_br_miss & ex_br_miss_misalign)
      ecause = IALIGN;
    else
      exc = 0;
  end

  always_ff @(posedge clk)
    if(!mem_stall) begin
      mem_exc <= exc & ~wb_exc;
      mem_exc_cause <= ecause;
    end

  assign ex_stall = ex_valid & (mem_stall | (mul_go & ~mul_done));
  always_ff @(posedge clk)
    if(~reset_n)
      mem_valid <= 0;
    else
      mem_valid <= mem_stall | (ex_valid & ~ex_stall & ~exc & ~wb_exc);

`ifndef SYNTHESIS
  always_ff @(posedge clk)
    if(ex_stall)
      $display("%d: stage_execute: stalling", $stime);
`endif

endmodule
