`timescale 1ns/1ps
`default_nettype none

module stage_decode(
  input             clk,
  input             reset_n,

  // inputs from fetch stage
  input             de_valid,
  input [31:0]      de_insn,
  input [31:0]      de_pc,

  // inputs from execute stage
  input             ex_stall,

  // inputs from mem stage
  input [4:0]       mem_wreg,
  input [31:0]      mem_wdata,
  input             mem_wen,

  // inputs from write stage
  input [4:0]       wb_wreg,
  input [31:0]      wb_wdata,
  input             wb_wen,

  // outputs to fetch stage
  output            de_stall,

  // outputs to execute stage
  output reg        ex_valid,

  output reg [31:0] ex_pc,
  output reg [31:0] ex_rdata1,
  output reg [31:0] ex_rdata2,
  output reg [31:0] ex_imm,

  output reg        ex_use_pc0,
  output reg        ex_use_pc1,
  output reg        ex_use_imm,
  output reg        ex_sub_sra,
  output reg [3:0]  ex_op,

  output reg        mem_read,
  output reg        mem_write,
  output reg        mem_extend,
  output reg [1:0]  mem_width,

  output reg        mem_jmp,
  output reg        mem_br,
  output reg        mem_br_inv,

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

    always @(posedge clk)
      if(!ex_stall)
        ex_pc <= de_pc;

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

    always @(posedge clk)
      if(!ex_stall)
        case(format)
          FORMAT_I: ex_imm <= {{21{de_insn[31]}},de_insn[30:20]};
          FORMAT_S: ex_imm <= {{21{de_insn[31]}},de_insn[30:25],de_insn[11:7]};
          FORMAT_B: ex_imm <= {{20{de_insn[31]}},de_insn[7],de_insn[30:25],de_insn[11:8],1'b0};
          FORMAT_U: ex_imm <= {de_insn[31:12],12'b0};
          FORMAT_J: ex_imm <= {{12{de_insn[31]}},de_insn[19:12],de_insn[20],de_insn[30:21],1'b0};
          default: ex_imm <= 32'b0;
        endcase

    always @(posedge clk)
      if(!ex_stall)
        if((opcode != OP_BRANCH) & (opcode != OP_STORE))
          wb_reg <= de_insn[11:7];
        else
          wb_reg <= 5'b0;

    wire [4:0] rs1 = de_insn[19:15];
    wire [4:0] rs2 = de_insn[24:20];
    wire [4:0] rd = de_insn[11:7];

    wire rs1_valid, rs2_valid;
    wire [31:0] rdata1, rdata2;
    regfile regfile(
      .clk(clk),
      .reset_n(reset_n),
      
      .rs1(rs1),
      .rs1_valid(rs1_valid),
      .rs1_data(rdata1),

      .rs2(rs2),
      .rs2_valid(rs2_valid),
      .rs2_data(rdata2),

      .rd(rd),
      .reserve(de_valid & ~de_stall & (opcode != OP_BRANCH) & (opcode != OP_STORE)),

      .wreg0(mem_wreg),
      .wdata0(mem_wdata),
      .wen0(mem_wen),

      .wreg1(wb_wreg),
      .wdata1(wb_wdata),
      .wen1(wb_wen)
      );

    always @(posedge clk)
      if(!ex_stall)
        begin
            ex_rdata1 <= rdata1;
            ex_rdata2 <= rdata2;
        end

    always @(posedge clk)
      if(!ex_stall)
        begin
            ex_use_pc0 <= (opcode == OP_JAL) | (opcode == OP_AUIPC);
            ex_use_pc1 <= (opcode == OP_JAL) | (opcode == OP_BRANCH);
            ex_use_imm <= (format != FORMAT_R) & (opcode != OP_BRANCH);
            ex_sub_sra <= (opcode == OP_OP) & funct7[5];
        end

    wire [2:0] funct3 = de_insn[14:12];
    wire [6:0] funct7 = de_insn[31:25];
    always @(posedge clk)
      if(!ex_stall)
        case(opcode)
          OP_OP, OP_OP_IMM:
            case({(funct7[0] & (opcode != OP_OP_IMM)), funct3})
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

    always @(posedge clk)
      if(!ex_stall)
        begin
            mem_jmp <= opcode == OP_JAL || opcode == OP_JALR;
            mem_br <= opcode == OP_BRANCH;
            mem_br_inv <= funct3[0];
        end

    `ifndef SYNTHESIS
    always @(posedge clk)
      if(de_stall)
        $display("%d: stage_decode: stalling", $stime);
    `endif

    wire error = format[6];
    assign de_stall = de_valid & (ex_stall | error | (~rs1_valid | ~rs2_valid));
    always @(posedge clk)
      if(~reset_n)
        ex_valid <= 0;
      else
        ex_valid <= ex_stall | (de_valid & ~de_stall);

endmodule
