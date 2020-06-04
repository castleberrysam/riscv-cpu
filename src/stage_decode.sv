`timescale 1ns/1ps

`include "defines.svh"

module stage_decode(
  input logic         clk,
  input logic         reset_n,

  // inputs from fetch stage
  input logic         de_valid,
  input logic         de_exc,
  input logic [31:0]  de_insn,
  input logic [31:2]  de_pc,

  // inputs from execute stage
  input logic         ex_stall,
  input logic         ex_br_miss,

  // inputs from the forwarding unit
  input logic         fwd_stall,
  input fwd_type_t    fwd_rs1,
  input fwd_type_t    fwd_rs2,

  // inputs for forwarding from execute and mem.
  input logic [31:0]  ex_forward_data,
  input logic [31:0]  mem_forward_data,

  // inputs from write stage
  input logic         wb_exc,
  input logic [4:0]   wb_wreg,
  input logic [31:0]  wb_wdata,
  input logic         wb_wen,

  // outputs to fetch stage
  output logic        de_stall,
  output logic        de_setpc,
  output logic [31:2] de_newpc,

  // outputs for forwarding
  output logic [4:0]  de_rs1,
  output logic [4:0]  de_rs2,

  // outputs to execute stage
  output logic        ex_valid,
  output logic        ex_exc,
  output ecause_t     ex_exc_cause,

  output logic [31:2] ex_pc,
  output logic [31:0] ex_rdata1,
  output logic [31:0] ex_rdata2,
  output logic [31:0] ex_imm,

  output logic        ex_use_pc,
  output logic        ex_use_imm,
  output logic        ex_sub_sra,
  output logic        ex_data1_sel,
  output aluop_t      ex_op,

  output logic        ex_br,
  output logic        ex_br_inv,
  output logic        ex_br_taken,

  output logic        ex_br_misalign,
  output logic        ex_br_miss_misalign,

  output logic        mem_read,
  output logic        mem_write,
  output logic        mem_extend,
  output logic [1:0]  mem_width,

  output logic [4:0]  wb_reg
  );

  // format decoder
  struct packed {
    logic r, i, s, b, u, j, invalid;
  } format;

  opcode_t opcode;
  assign opcode = opcode_t'(de_insn[6:2]);
  always_comb begin
    format = '{default:0};
    if(de_insn[1:0] != 'b11)
      format.invalid = 1;
    else
      unique case(opcode)
        OP: format.r = 1;
        OP_IMM: format.i = 1;

        LOAD: format.i = 1;
        STORE: format.s = 1;

        LUI: format.u = 1;
        AUIPC: format.u = 1;

        JAL: format.j = 1;
        JALR: format.i = 1;
        BRANCH: format.b = 1;

        MISC_MEM: format.i = 1;
        SYSTEM: format.i = 1;

        default: format.invalid = 1;
      endcase
  end

  logic [4:0] rs1, rs2, rd;
  assign rs1 = de_insn[19:15];
  assign rs2 = de_insn[24:20];
  assign rd = de_insn[11:7];

  logic [2:0] funct3;
  logic [6:0] funct7;
  assign funct3 = de_insn[14:12];
  assign funct7 = de_insn[31:25];

  logic csr;
  assign csr = (opcode == SYSTEM) & |funct3[1:0];

  // immediate decoder
  logic [31:0] imm;
  always_comb
    unique case(1)
      format.i: imm = {{21{de_insn[31]}},de_insn[30:20]};
      format.s: imm = {{21{de_insn[31]}},de_insn[30:25],de_insn[11:7]};
      format.b: imm = {{20{de_insn[31]}},de_insn[7],de_insn[30:25],de_insn[11:8],1'b0};
      format.u: imm = {de_insn[31:12],12'b0};
      format.j: imm = {{12{de_insn[31]}},de_insn[19:12],de_insn[20],de_insn[30:21],1'b0};
      format.invalid: imm = de_insn;
      default: imm = 0;
    endcase

  logic jump;
  always_ff @(posedge clk)
    if(!ex_stall)
      ex_imm <= jump ? 4 : imm;

  // register file
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

  always_ff @(posedge clk)
    if(!ex_stall)
      if((opcode != BRANCH) & (opcode != STORE))
        wb_reg <= de_insn[11:7];
      else
        wb_reg <= 0;

  // forwarding
  assign de_rs1 = rs1;
  assign de_rs2 = rs2;

  logic [31:0] rdata1, rdata2;
  always_comb begin
    if(fwd_rs1.ex & ~jalr)
      rdata1 = ex_forward_data;
    else if(fwd_rs1.mem)
      rdata1 = mem_forward_data;
    else
      rdata1 = rf_rdata1;

    if(fwd_rs2.ex)
      rdata2 = ex_forward_data;
    else if(fwd_rs2.mem)
      rdata2 = mem_forward_data;
    else
      rdata2 = rf_rdata2;
  end

  always_ff @(posedge clk)
    if(!ex_stall) begin
      ex_rdata1 <= (csr & funct3[2]) ? rs1 : rdata1;
      ex_rdata2 <= rdata2;
    end

  // branches and jumps
  logic br_take;
  assign br_take = imm[31];
  
  // opcode[4]: set for JAL/JALR/B/ECALL/EBREAK/CSR*
  // opcode[2]: set for ECALL/EBREAK/CSR*
  // opcode[0]: set for JAL/JALR
  logic transfer, jalr;
  assign transfer = opcode[4] & ~opcode[2];
  assign jump = transfer & opcode[0];
  assign jalr = jump & ~opcode[1];

  logic [31:0] br_miss_pc;
  always_comb
    br_miss_pc = {de_pc,2'b0} + (br_take ? 4 : imm);

  logic [31:2] br_miss_pc_r;
  always_ff @(posedge clk)
    br_miss_pc_r <= br_miss_pc[31:2];

  logic [31:0] newpc;
  always_comb
    if(ex_br_miss) begin
      de_setpc = 1;
      newpc = {br_miss_pc_r,2'b0};
    end else if(de_valid & transfer & (jump | br_take)) begin
      de_setpc = 1;
      if(jalr)
        newpc = (rdata1 + imm) & ~1;
      else
        newpc = {de_pc,2'b0} + imm;
    end else begin
      de_setpc = 0;
      newpc = 0;
    end

  logic misalign;
  assign de_newpc = newpc[31:2];
  assign misalign = |newpc[1:0];

  always_ff @(posedge clk)
    if(!ex_stall) begin
      ex_pc <= de_pc;
      ex_br <= opcode == BRANCH;
      ex_br_inv <= funct3[0];
      ex_br_taken <= br_take;
      ex_br_misalign <= misalign;
      ex_br_miss_misalign <= |br_miss_pc[1:0];
    end

  // control signal decoder
  always_ff @(posedge clk)
    if(!ex_stall) begin
      ex_use_pc <= (opcode == JAL) | (opcode == JALR) | (opcode == AUIPC);
      ex_use_imm <= ~format.r & (opcode != BRANCH);
      ex_data1_sel <= csr;
      ex_sub_sra <= (opcode == OP) & funct7[5];
    end

  logic mul;
  assign mul = (opcode == OP) & funct7[0];
  always_ff @(posedge clk)
    if(!ex_stall) begin
      ex_op <= '{default:0};
      unique0 case(opcode)
        OP, OP_IMM:
          case({mul,funct3})
            'b0000: ex_op.add <= 1;
            'b0001: ex_op.sl <= 1;
            'b0010: ex_op.slt <= 1;
            'b0011: ex_op.sltu <= 1;
            'b0100: ex_op.xor_ <= 1;
            'b0101: ex_op.sr <= 1;
            'b0110: ex_op.or_ <= 1;
            'b0111: ex_op.and_ <= 1;
            // M extension.
            'b1000: ex_op.mul <= 1;
            'b1001: ex_op.mulh <= 1;
            'b1010: ex_op.mulhsu <= 1;
            'b1011: ex_op.mulhu <= 1;
          endcase

        LOAD, STORE: ex_op.add <= 1;

        LUI: ex_op.nop <= 1;
        AUIPC: ex_op.add <= 1;

        JAL, JALR: ex_op.add <= 1;
        BRANCH:
          unique casez(funct3[2:1])
            'b0?: ex_op.seq <= 1;
            'b10: ex_op.slt <= 1;
            'b11: ex_op.sltu <= 1;
          endcase

        MISC_MEM, SYSTEM: ex_op.nop <= 1;
      endcase
    end

  always_ff @(posedge clk)
    if(!ex_stall) begin
      // hijack the mem signals for csr accesses
      if(csr) begin
        mem_read   <= 1;
        mem_write  <= 1;
        // csr_read
        mem_extend <= |rd;
        // csr_write
        mem_width  <= |rs1 ? funct3[1:0] : 0;
      end else begin
        mem_read   <= opcode == LOAD;
        mem_write  <= opcode == STORE;
        mem_extend <= funct3[2];
        mem_width  <= funct3[1:0];
      end
    end

  // stall/valid logic
  logic test_stop;
`ifndef SYNTHESIS
  assign test_stop = de_insn == TEST_MAGIC;
`else
  assign test_stop = 0;
`endif

  logic ecall, ebreak;
  assign ecall = (opcode == SYSTEM) & ~|funct3[1:0] & ~de_insn[20];
  assign ebreak = (opcode == SYSTEM) & ~|funct3[1:0] & de_insn[20];

  logic exc;
  ecause_t ecause;
  always_comb begin
    exc = 1;
    unique if(de_exc)
      ecause = IFAULT;
    else if(de_valid & format.invalid)
      // imm = de_insn (in immediate decoder)
      ecause = IILLEGAL;
    else if(de_valid & jump & misalign)
      ecause = IALIGN;
    else if(de_valid & ebreak)
      ecause = EBREAK;
    else if(de_valid & ecall)
      ecause = MCALL;
    else
      exc = 0;
  end

  always_ff @(posedge clk)
    if(!ex_stall) begin
      ex_exc <= exc & ~wb_exc & ~test_stop;
      ex_exc_cause <= ecause;
    end

  logic jalr_stall;
  assign jalr_stall = jalr & fwd_rs1.ex;

  assign de_stall = de_valid & (ex_stall | test_stop | jalr_stall | fwd_stall);
  always_ff @(posedge clk)
    if(~reset_n)
      ex_valid <= 0;
    else
      ex_valid <= ex_stall | (de_valid & ~de_stall & ~ex_br_miss & ~exc & ~wb_exc);

`ifndef SYNTHESIS
  always_ff @(posedge clk)
    if(de_stall & ~format.invalid)
      $display("%d: stage_decode: stalling", $stime);
`endif

endmodule
