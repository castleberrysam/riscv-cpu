`timescale 1ns/1ps
`default_nettype none

module stage_decode(
  input wire        clk,
  input wire        reset_n,

  // inputs from fetch stage
  input wire        de_valid,
  input wire [31:0] de_insn,
  input wire [31:0] de_pc,

  // inputs from execute stage
  input wire        ex_stall,

  input wire        ex_br_miss,

  // inputs from the forwarding unit
  input wire        load_stall,

  input wire [1:0]  forward_rs1,
  input wire [1:0]  forward_rs2,

  // inputs for forwarding from execute and mem.
  input wire [31:0] ex_forward_data,
  input wire [31:0] mem_forward_data,

  // inputs from write stage
  input wire [4:0]  wb_wreg,
  input wire [31:0] wb_wdata,
  input wire        wb_wen,

  // outputs to fetch stage
  output wire       de_stall,

  output reg        de_setpc,
  output reg [31:0] de_newpc,

  // outputs for forwarding
  output wire [4:0] de_rs1,
  output wire [4:0] de_rs2,

  // outputs to execute stage
  output reg        ex_valid,

  output reg [31:0] ex_pc,
  output reg [31:0] ex_rdata1,
  output reg [31:0] ex_rdata2,
  output reg [31:0] ex_imm,

  output reg        ex_use_pc,
  output reg        ex_use_imm,
  output reg        ex_sub_sra,
  output reg [3:0]  ex_op,

  output reg        ex_br,
  output reg        ex_br_inv,
  output reg        ex_br_taken,

  output reg        mem_read,
  output reg        mem_write,
  output reg        mem_extend,
  output reg [1:0]  mem_width,

  output reg [4:0]  wb_reg
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

    wire br_take = imm[31];
    wire jalr = opcode == OP_JALR;

    reg [31:0] br_miss_pc;
    always @(posedge clk)
      br_miss_pc <= de_pc + (br_take ? 32'd4 : imm);

    // opcode[4]: set for JAL/JALR/B/ECALL/EBREAK
    // opcode[0]: set for JAL/JALR
    always @(*)
      if(ex_br_miss)
        begin
            de_setpc = 1;
            de_newpc = br_miss_pc;
        end
      else if(de_valid & opcode[4] & (opcode[0] | br_take))
        begin
            de_setpc = 1;
            de_newpc = (jalr ? rdata1 : de_pc) + imm;
        end
      else
        begin
            de_setpc = 0;
            de_newpc = 32'b0;
        end

    always @(posedge clk)
      if(!ex_stall)
        begin
            ex_pc <= de_pc;
            ex_br <= opcode == OP_BRANCH;
            ex_br_inv <= funct3[0];
            ex_br_taken <= br_take;
        end

    wire [4:0] opcode = de_insn[6:2];
    reg [6:0] format;
    always @(*)
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

    reg [31:0] imm;
    always @(*)
      case(format)
        FORMAT_I: imm = {{21{de_insn[31]}},de_insn[30:20]};
        FORMAT_S: imm = {{21{de_insn[31]}},de_insn[30:25],de_insn[11:7]};
        FORMAT_B: imm = {{20{de_insn[31]}},de_insn[7],de_insn[30:25],de_insn[11:8],1'b0};
        FORMAT_U: imm = {de_insn[31:12],12'b0};
        FORMAT_J: imm = {{12{de_insn[31]}},de_insn[19:12],de_insn[20],de_insn[30:21],1'b0};
        default: imm = 32'b0;
      endcase

    always @(posedge clk)
      if(!ex_stall)
        ex_imm <= (opcode[4] & opcode[0]) ? 32'd4 : imm;

    always @(posedge clk)
      if(!ex_stall)
        if((opcode != OP_BRANCH) & (opcode != OP_STORE))
          wb_reg <= de_insn[11:7];
        else
          wb_reg <= 5'b0;

    wire [4:0] rs1 = de_insn[19:15];
    wire [4:0] rs2 = de_insn[24:20];
    wire [4:0] rd = de_insn[11:7];

    assign de_rs1 = rs1;
    assign de_rs2 = rs2;

    wire [31:0] rf_rdata1, rf_rdata2;
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

    reg [31:0] rdata1, rdata2;
    always @(*)
      begin
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

    always @(posedge clk)
      if(!ex_stall)
        begin
            ex_rdata1 <= rdata1;
            ex_rdata2 <= rdata2;
        end

    always @(posedge clk)
      if(!ex_stall)
        begin
            ex_use_pc <= (opcode == OP_JAL) | (opcode == OP_JALR) | (opcode == OP_AUIPC);
            ex_use_imm <= (format != FORMAT_R) & (opcode != OP_BRANCH);
            ex_sub_sra <= (opcode == OP_OP) & funct7[5];
        end

    wire [2:0] funct3 = de_insn[14:12];
    wire [6:0] funct7 = de_insn[31:25];
    wire mul = (opcode == OP_OP) & funct7[0];
    always @(posedge clk)
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

    always @(posedge clk)
      if(!ex_stall)
        begin
            mem_read <= opcode == OP_LOAD;
            mem_write <= opcode == OP_STORE;
            mem_extend <= funct3[2];
            mem_width <= funct3[1:0];
        end

    `ifndef SYNTHESIS
    always @(posedge clk)
      if(de_stall & ~error)
        $display("%d: stage_decode: stalling", $stime);
    `endif

    wire jalr_stall = jalr & (forward_rs1 == FORWARDING_EX);

    wire error = format[6];
    assign de_stall = de_valid & (ex_stall | error | jalr_stall | load_stall);
    always @(posedge clk)
      if(~reset_n)
        ex_valid <= 0;
      else
        ex_valid <= ex_stall | (de_valid & ~de_stall & ~ex_br_miss);

endmodule
