`timescale 1ns/1ps
`default_nettype none

module top(
  input clk,
  input reset_n
  );

    wire        de_stall;
    wire        ex_stall;
    wire        mem_stall;
    wire        wb_stall;

    wire        fe_enable;
    wire        pc_wen;
    wire [31:0] pc;

    wire        fe_req;
    wire [31:0] fe_addr;
    wire        fe_ack;
    wire [31:0] fe_data;

    wire        de_valid;
    wire [31:0] de_insn;
    wire [31:0] de_pc;

    wire [4:0]  mem_wreg;
    wire [31:0] mem_wdata;

    wire [4:0]  wb_wreg;
    wire [31:0] wb_wdata;
    wire        wb_wen;

    wire        ex_valid;
    wire [31:0] ex_pc;
    wire [31:0] ex_rdata1;
    wire [31:0] ex_rdata2;
    wire [31:0] ex_imm;

    wire        ex_use_pc0;
    wire        ex_use_pc1;
    wire        ex_use_imm;
    wire        ex_sub_sra;
    wire [3:0]  ex_op;

    wire [4:0]  de_rs1;
    wire [4:0]  de_rs2;

    wire [1:0]  forward_rs1;
    wire [1:0]  forward_rs2;

    wire [31:0] ex_forward_data;
    wire        ex_wen;
    wire        mem_wen;

    wire        mem_read;
    wire        mem_write;
    wire        mem_extend;
    wire [1:0]  mem_width;

    wire        mem_jmp;
    wire        mem_br;
    wire        mem_br_inv;

    wire [4:0]  wb_reg;

    wire        mem_valid;

    wire [31:0] mem_pc;

    wire [31:0] mem_data0;
    wire [31:0] mem_data1;

    wire        mem_read_r;
    wire        mem_write_r;
    wire        mem_extend_r;
    wire [1:0]  mem_width_r;

    wire        mem_jmp_r;
    wire        mem_br_r;
    wire        mem_br_inv_r;

    wire [4:0]  wb_reg_r;

    wire        mem_req;
    wire [31:0] mem_addr;
    wire        mem_write_out;
    wire [31:0] mem_data_out;
    wire        mem_extend_out;
    wire [1:0]  mem_width_out;
    wire        mem_ack;
    wire [31:0] mem_data_in;

    wire        wb_valid;

    wire [31:0] wb_pc;

    wire [4:0]  wb_reg_r_r;
    wire [31:0] wb_data;

    stage_fetch fetch(
      .clk(clk),
      .reset_n(reset_n),

      .de_stall(de_stall),

      .fe_enable(fe_enable),
      .pc_wen(pc_wen),
      .pc_in(pc),

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

      .ex_forward_data(ex_forward_data),
      .mem_forward_data(mem_data0),
      .forward_rs1(forward_rs1),
      .forward_rs2(forward_rs2),
                        
      .wb_wreg(wb_wreg),
      .wb_wdata(wb_wdata),
      .wb_wen(wb_wen),

      .de_stall(de_stall),

      .ex_valid(ex_valid),
      .ex_pc(ex_pc),
      .ex_rdata1(ex_rdata1),
      .ex_rdata2(ex_rdata2),
      .ex_imm(ex_imm),

      .ex_use_pc0(ex_use_pc0),
      .ex_use_pc1(ex_use_pc1),
      .ex_use_imm(ex_use_imm),
      .ex_sub_sra(ex_sub_sra),
      .ex_op(ex_op),

      .mem_read(mem_read),
      .mem_write(mem_write),
      .mem_extend(mem_extend),
      .mem_width(mem_width),

      .mem_jmp(mem_jmp),
      .mem_br(mem_br),
      .mem_br_inv(mem_br_inv),

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

      .ex_use_pc0(ex_use_pc0),
      .ex_use_pc1(ex_use_pc1),
      .ex_use_imm(ex_use_imm),
      .ex_sub_sra(ex_sub_sra),
      .ex_op(ex_op),

      .ex_wen(ex_wen),
      .ex_forward_data(ex_forward_data),

      .mem_read(mem_read),
      .mem_write(mem_write),
      .mem_extend(mem_extend),
      .mem_width(mem_width),

      .mem_jmp(mem_jmp),
      .mem_br(mem_br),
      .mem_br_inv(mem_br_inv),

      .wb_reg(wb_reg),

      .mem_stall(mem_stall),

      .ex_stall(ex_stall),

      .mem_valid(mem_valid),

      .mem_pc(mem_pc),

      .mem_data0(mem_data0),
      .mem_data1(mem_data1),

      .mem_read_r(mem_read_r),
      .mem_write_r(mem_write_r),
      .mem_extend_r(mem_extend_r),
      .mem_width_r(mem_width_r),

      .mem_jmp_r(mem_jmp_r),
      .mem_br_r(mem_br_r),
      .mem_br_inv_r(mem_br_inv_r),

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

      .mem_jmp(mem_jmp_r),
      .mem_br(mem_br_r),
      .mem_br_inv(mem_br_inv_r),

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

      .fe_enable(fe_enable),
      .pc_wen(pc_wen),
      .pc(pc),

      .mem_stall(mem_stall),
      .mem_wen(mem_wen),

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
      .ex_rd(wb_reg),
      .mem_rd(wb_reg_r),
      .ex_wen(ex_wen),
      .mem_wen(mem_wen),

      .forward_rs1(forward_rs1),
      .forward_rs2(forward_rs2)     
      );

endmodule
