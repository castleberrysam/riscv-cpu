`timescale 1ns/1ps

module stage_decode(
  input logic         clk,
  input logic         reset_n,

  // inputs from fetch stage
  input logic         de_valid,
  input logic [31:0]  de_insn,
  input logic [31:0]  de_pc,

  // inputs from execute stage
  input logic         ex_stall,
  input logic         ex_br_miss,

  // inputs from the forwarding unit
  input logic         load_stall,
  input logic [1:0]   forward_rs1,
  input logic [1:0]   forward_rs2,

  // inputs for forwarding from execute and mem.
  input logic [31:0]  ex_forward_data,
  input logic [31:0]  mem_forward_data,

  // inputs from write stage
  input logic [4:0]   wb_wreg,
  input logic [31:0]  wb_wdata,
  input logic         wb_wen,

  // outputs to fetch stage
  output logic        de_stall,
  output logic        de_setpc,
  output logic [31:0] de_newpc,

  // outputs for forwarding
  output logic [4:0]  de_rs1,
  output logic [4:0]  de_rs2,

  // outputs to execute stage
  output logic        ex_valid,

  output logic [31:0] ex_pc,
  output logic [31:0] ex_rdata1,
  output logic [31:0] ex_rdata2,
  output logic [31:0] ex_imm,

  output logic        ex_use_pc,
  output logic        ex_use_imm,
  output logic        ex_sub_sra,
  output logic [3:0]  ex_op,

  output logic        ex_br,
  output logic        ex_br_inv,
  output logic        ex_br_taken,

  output logic        mem_read,
  output logic        mem_write,
  output logic        mem_extend,
  output logic [1:0]  mem_width,

  output logic [4:0]  wb_reg
  );

`include "defines.vh"

  localparam
    FORMAT_R = 7'b0000001,
    FORMAT_I = 7'b0000010,
    FORMAT_S = 7'b0000100,
    FORMAT_B = 7'b0001000,
    FORMAT_U = 7'b0010000,
    FORMAT_J = 7'b0100000,
    FORMAT_INVALID = 7'b1000000;

  logic br_take;
  assign br_take = imm[31];
  logic jalr;
  assign jalr = opcode == OP_JALR;

  logic [31:0] br_miss_pc;
  always_ff @(posedge clk)
    br_miss_pc <= de_pc + (br_take ? 32'd4 : imm);

  // opcode[4]: set for JAL/JALR/B/ECALL/EBREAK
  // opcode[0]: set for JAL/JALR
  always_comb
    if(ex_br_miss) begin
      de_setpc = 1;
      de_newpc = br_miss_pc;
    end else if(de_valid & opcode[4] & (opcode[0] | br_take)) begin
      de_setpc = 1;
      de_newpc = (jalr ? rdata1 : de_pc) + imm;
    end else begin
      de_setpc = 0;
      de_newpc = 32'b0;
    end

  always_ff @(posedge clk)
    if(!ex_stall) begin
      ex_pc <= de_pc;
      ex_br <= opcode == OP_BRANCH;
      ex_br_inv <= funct3[0];
      ex_br_taken <= br_take;
    end

  logic [4:0] opcode;
  assign opcode = de_insn[6:2];
  logic [6:0] format;
  always_comb
    if(de_insn[1:0] != 2'b11)
      format = FORMAT_INVALID;
    else
      case(opcode)
        OP_OP: format = FORMAT_R;
        OP_OP_IMM: format = FORMAT_I;

        OP_LOAD: format = FORMAT_I;
        OP_STORE: format = FORMAT_S;

        OP_LUI: format = FORMAT_U;
        OP_AUIPC: format = FORMAT_U;

        OP_JAL: format = FORMAT_J;
        OP_JALR: format = FORMAT_I;
        OP_BRANCH: format = FORMAT_B;

        OP_MISC_MEM: format = FORMAT_I;
        OP_SYSTEM: format = FORMAT_I;
        default: format = FORMAT_INVALID;
      endcase

  logic [31:0] imm;
  always_comb
    case(format)
      FORMAT_I: imm = {{21{de_insn[31]}},de_insn[30:20]};
      FORMAT_S: imm = {{21{de_insn[31]}},de_insn[30:25],de_insn[11:7]};
      FORMAT_B: imm = {{20{de_insn[31]}},de_insn[7],de_insn[30:25],de_insn[11:8],1'b0};
      FORMAT_U: imm = {de_insn[31:12],12'b0};
      FORMAT_J: imm = {{12{de_insn[31]}},de_insn[19:12],de_insn[20],de_insn[30:21],1'b0};
      default: imm = 32'b0;
    endcase

  always_ff @(posedge clk)
    if(!ex_stall)
      ex_imm <= (opcode[4] & opcode[0]) ? 32'd4 : imm;

  always_ff @(posedge clk)
    if(!ex_stall)
      if((opcode != OP_BRANCH) & (opcode != OP_STORE))
        wb_reg <= de_insn[11:7];
      else
        wb_reg <= 5'b0;

  logic [4:0] rs1, rs2, rd;
  assign rs1 = de_insn[19:15];
  assign rs2 = de_insn[24:20];
  assign rd = de_insn[11:7];

  assign de_rs1 = rs1;
  assign de_rs2 = rs2;

  logic [31:0] rf_rdata1, rf_rdata2;
  regfile regfile(
    .clk(clk),
    .reset_n(reset_n),

    .rs1(rs1),
    .rdata1(rf_rdata1),

    .rs2(rs2),
    .rdata2(rf_rdata2),

    .wreg(wb_wreg),
    .wdata(wb_wdata),
    .wen(wb_wen)
    );

  logic [31:0] rdata1, rdata2;
  always_comb begin
    if((forward_rs1 == FORWARDING_EX) & ~jalr)
      rdata1 = ex_forward_data;
    else if(forward_rs1 == FORWARDING_MEM)
      rdata1 = mem_forward_data;
    else
      rdata1 = rf_rdata1;

    if(forward_rs2 == FORWARDING_EX)
      rdata2 = ex_forward_data;
    else if(forward_rs2 == FORWARDING_MEM)
      rdata2 = mem_forward_data;
    else
      rdata2 = rf_rdata2;
  end

  always_ff @(posedge clk)
    if(!ex_stall) begin
      ex_rdata1 <= rdata1;
      ex_rdata2 <= rdata2;
    end

  always_ff @(posedge clk)
    if(!ex_stall) begin
      ex_use_pc <= (opcode == OP_JAL) | (opcode == OP_JALR) | (opcode == OP_AUIPC);
      ex_use_imm <= (format != FORMAT_R) & (opcode != OP_BRANCH);
      ex_sub_sra <= (opcode == OP_OP) & funct7[5];
    end

  logic [2:0] funct3;
  logic [6:0] funct7;
  logic mul;
  assign funct3 = de_insn[14:12];
  assign funct7 = de_insn[31:25];
  assign mul = (opcode == OP_OP) & funct7[0];
  always_ff @(posedge clk)
    if(!ex_stall)
      case(opcode)
        OP_OP, OP_OP_IMM:
          case({mul,funct3})
            4'b0000: ex_op <= ALUOP_ADD;
            4'b0001: ex_op <= ALUOP_SL;
            4'b0010: ex_op <= ALUOP_SLT;
            4'b0011: ex_op <= ALUOP_SLTU;
            4'b0100: ex_op <= ALUOP_XOR;
            4'b0101: ex_op <= ALUOP_SR;
            4'b0110: ex_op <= ALUOP_OR;
            4'b0111: ex_op <= ALUOP_AND;
            // M extension.
            4'b1000: ex_op <= ALUOP_MUL;
            4'b1001: ex_op <= ALUOP_MULH;
            4'b1010: ex_op <= ALUOP_MULHSU;
            4'b1011: ex_op <= ALUOP_MULHU;
          endcase

        OP_LOAD, OP_STORE: ex_op <= ALUOP_ADD;

        OP_LUI: ex_op <= ALUOP_NOP;
        OP_AUIPC: ex_op <= ALUOP_ADD;

        OP_JAL, OP_JALR: ex_op <= ALUOP_ADD;
        OP_BRANCH:
          casez(funct3[2:1])
            2'b0?: ex_op <= ALUOP_SEQ;
            2'b10: ex_op <= ALUOP_SLT;
            2'b11: ex_op <= ALUOP_SLTU;
          endcase

        OP_MISC_MEM, OP_SYSTEM: ex_op <= ALUOP_NOP;
      endcase

  always_ff @(posedge clk)
    if(!ex_stall) begin
      mem_read <= opcode == OP_LOAD;
      mem_write <= opcode == OP_STORE;
      mem_extend <= funct3[2];
      mem_width <= funct3[1:0];
    end

`ifndef SYNTHESIS
  always_ff @(posedge clk)
    if(de_stall & ~error)
      $display("%d: stage_decode: stalling", $stime);
`endif

  logic jalr_stall;
  assign jalr_stall = jalr & (forward_rs1 == FORWARDING_EX);

  logic error;
  assign error = format[6];
  assign de_stall = de_valid & (ex_stall | error | jalr_stall | load_stall);
  always_ff @(posedge clk)
    if(~reset_n)
      ex_valid <= 0;
    else
      ex_valid <= ex_stall | (de_valid & ~de_stall & ~ex_br_miss);

endmodule
