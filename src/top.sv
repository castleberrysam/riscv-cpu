`timescale 1ns/1ps

module top(
  input logic clk,
  input logic reset_n
  );

  logic        de_stall;
  logic        ex_stall;
  logic        mem_stall;
  logic        wb_stall;

  logic        de_setpc;
  logic [31:0] de_newpc;

  logic        ex_br_miss;

  logic        fe_req;
  logic [31:0] fe_addr;
  logic        fe_ack;
  logic [31:0] fe_data;

  logic        de_valid;
  logic [31:0] de_insn;
  logic [31:0] de_pc;

  logic        load_stall;

  logic [1:0]  forward_rs1;
  logic [1:0]  forward_rs2;

  logic [4:0]  wb_wreg;
  logic [31:0] wb_wdata;
  logic        wb_wen;

  logic        ex_valid;
  logic [31:0] ex_pc;
  logic [31:0] ex_rdata1;
  logic [31:0] ex_rdata2;
  logic [31:0] ex_imm;

  logic        ex_use_pc;
  logic        ex_use_imm;
  logic        ex_sub_sra;
  logic [3:0]  ex_op;

  logic        ex_br;
  logic        ex_br_inv;
  logic        ex_br_taken;

  logic [4:0]  de_rs1;
  logic [4:0]  de_rs2;

  logic [31:0] ex_forward_data;
  logic        ex_wen;
  logic        mem_wen;

  logic        mem_read;
  logic        mem_write;
  logic        mem_extend;
  logic [1:0]  mem_width;

  logic [4:0]  wb_reg;

  logic        mem_valid;

  logic [31:0] mem_pc;

  logic [31:0] mem_data0;
  logic [31:0] mem_data1;

  logic        mem_read_r;
  logic        mem_write_r;
  logic        mem_extend_r;
  logic [1:0]  mem_width_r;

  logic [4:0]  wb_reg_r;

  logic        mem_req;
  logic [31:0] mem_addr;
  logic        mem_write_out;
  logic [31:0] mem_data_out;
  logic        mem_extend_out;
  logic [1:0]  mem_width_out;
  logic        mem_ack;
  logic [31:0] mem_data_in;

  logic        wb_valid;

  logic [31:0] wb_pc;

  logic [4:0]  wb_reg_r_r;
  logic [31:0] wb_data;

  stage_fetch fetch(
    .clk(clk),
    .reset_n(reset_n),

    .de_stall(de_stall),

    .de_setpc(de_setpc),
    .de_newpc(de_newpc),

    .fe_req(fe_req),
    .fe_addr(fe_addr),
    .fe_ack(fe_ack),
    .fe_data(fe_data),

    .de_valid(de_valid),
    .de_insn(de_insn),
    .de_pc(de_pc)
    );

  stage_decode decode(
    .clk(clk),
    .reset_n(reset_n),

    .de_valid(de_valid),
    .de_insn(de_insn),
    .de_pc(de_pc),

    .de_rs1(de_rs1),
    .de_rs2(de_rs2),

    .ex_stall(ex_stall),

    .ex_br_miss(ex_br_miss),

    .load_stall(load_stall),

    .forward_rs1(forward_rs1),
    .forward_rs2(forward_rs2),

    .ex_forward_data(ex_forward_data),
    .mem_forward_data(mem_data0),

    .wb_wreg(wb_wreg),
    .wb_wdata(wb_wdata),
    .wb_wen(wb_wen),

    .de_stall(de_stall),

    .de_setpc(de_setpc),
    .de_newpc(de_newpc),

    .ex_valid(ex_valid),
    .ex_pc(ex_pc),
    .ex_rdata1(ex_rdata1),
    .ex_rdata2(ex_rdata2),
    .ex_imm(ex_imm),

    .ex_use_pc(ex_use_pc),
    .ex_use_imm(ex_use_imm),
    .ex_sub_sra(ex_sub_sra),
    .ex_op(ex_op),

    .ex_br(ex_br),
    .ex_br_inv(ex_br_inv),
    .ex_br_taken(ex_br_taken),

    .mem_read(mem_read),
    .mem_write(mem_write),
    .mem_extend(mem_extend),
    .mem_width(mem_width),

    .wb_reg(wb_reg)
    );

  stage_execute execute(
    .clk(clk),
    .reset_n(reset_n),

    .ex_valid(ex_valid),
    .ex_pc(ex_pc),
    .ex_rdata1(ex_rdata1),
    .ex_rdata2(ex_rdata2),
    .ex_imm(ex_imm),

    .ex_use_pc(ex_use_pc),
    .ex_use_imm(ex_use_imm),
    .ex_sub_sra(ex_sub_sra),
    .ex_op(ex_op),

    .ex_br(ex_br),
    .ex_br_inv(ex_br_inv),
    .ex_br_taken(ex_br_taken),

    .ex_forward_data(ex_forward_data),

    .mem_read(mem_read),
    .mem_write(mem_write),
    .mem_extend(mem_extend),
    .mem_width(mem_width),

    .wb_reg(wb_reg),

    .mem_stall(mem_stall),

    .ex_br_miss(ex_br_miss),

    .ex_stall(ex_stall),

    .mem_valid(mem_valid),

    .mem_pc(mem_pc),

    .mem_data0(mem_data0),
    .mem_data1(mem_data1),

    .mem_read_r(mem_read_r),
    .mem_write_r(mem_write_r),
    .mem_extend_r(mem_extend_r),
    .mem_width_r(mem_width_r),

    .wb_reg_r(wb_reg_r)
    );

  stage_mem mem(
    .clk(clk),
    .reset_n(reset_n),

    .mem_valid(mem_valid),

    .mem_pc(mem_pc),

    .mem_data0(mem_data0),
    .mem_data1(mem_data1),

    .mem_read(mem_read_r),
    .mem_write(mem_write_r),
    .mem_extend(mem_extend_r),
    .mem_width(mem_width_r),

    .wb_reg(wb_reg_r),

    .wb_stall(wb_stall),

    .req(mem_req),
    .addr(mem_addr),
    .write(mem_write_out),
    .data_out(mem_data_out),
    .extend(mem_extend_out),
    .width(mem_width_out),
    .ack(mem_ack),
    .data_in(mem_data_in),

    .mem_stall(mem_stall),

    .wb_valid(wb_valid),

    .wb_pc(wb_pc),

    .wb_reg_r(wb_reg_r_r),
    .wb_data(wb_data)
    );

  stage_write write(
    .clk(clk),
    .reset_n(reset_n),

    .wb_valid(wb_valid),

    .wb_pc(wb_pc),

    .wb_reg(wb_reg_r_r),
    .wb_data(wb_data),

    .wreg(wb_wreg),
    .wdata(wb_wdata),
    .wen(wb_wen),

    .wb_stall(wb_stall)
    );

  memory memory(
    .clk(clk),
    .reset_n(reset_n),

    .fe_req(fe_req),
    .fe_addr(fe_addr),
    .fe_ack(fe_ack),
    .fe_data(fe_data),

    .mem_req(mem_req),
    .mem_addr(mem_addr),
    .mem_write(mem_write_out),
    .mem_data_in(mem_data_out),
    .mem_extend(mem_extend_out),
    .mem_width(mem_width_out),
    .mem_ack(mem_ack),
    .mem_data_out(mem_data_in)
    );

  forward_unit forward_unit(
    .de_rs1(de_rs1),
    .de_rs2(de_rs2),

    .ex_valid(ex_valid),
    .mem_read(mem_read),
    .ex_rd(wb_reg),

    .mem_valid(mem_valid),
    .mem_read_r(mem_read_r),
    .mem_rd(wb_reg_r),

    .load_stall(load_stall),

    .forward_rs1(forward_rs1),
    .forward_rs2(forward_rs2)
    );

endmodule
