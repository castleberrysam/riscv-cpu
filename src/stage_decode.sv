`timescale 1ns/1ps

`include "defines.svh"

module stage_decode(
  input logic         clk_core,
  input logic         reset_n,

  // fetch0 outputs
  output logic        de_setpc,
  output logic [31:2] de_newpc,
  
  // fetch1 inputs/outputs
  input logic         fe1_valid,
  input logic         fe1_stall,
  output logic        de_stall,
  input logic         fe1_exc,
  input logic [31:2]  fe1_pc,

  input logic [31:0]  fe1_insn,

  // execute inputs/outputs
  input logic         ex_stall,
  input logic         ex_br_miss,

  input logic [31:0]  ex_fwd_data,

  output logic        de_valid,
  output logic        de_exc,
  output ecause_t     de_exc_cause,
  output logic [31:2] de_pc,

  output logic [31:0] de_rdata1,
  output logic [31:0] de_rdata2,
  output logic [31:0] de_imm,

  output logic        de_use_pc,
  output logic        de_use_imm,
  output logic        de_sub_sra,
  output logic        de_data1_sel,
  output aluop_t      de_op,

  output logic        de_br,
  output logic        de_br_inv,
  output logic        de_br_taken,

  output logic        de_br_misalign,
  output logic        de_br_miss_misalign,

  output logic        de_mem_read,
  output logic        de_mem_write,
  output logic        de_mem_extend,
  output logic [1:0]  de_mem_width,

  output logic [4:0]  de_wb_reg,

  // memory0 inputs
  input logic [31:0]  mem0_fwd_data,

  // memory1 inputs
  input logic [31:0]  mem1_fwd_data,

  // csr inputs
  input logic         csr_kill,

  // writeback inputs
  input logic         wb_valid,
  input logic [4:0]   wb_reg,
  input logic [31:0]  wb_data,

  // forward unit inputs/outputs
  input logic         fwd_stall,
  input fwd_type_t    fwd_rs1,
  input fwd_type_t    fwd_rs2,

  output logic [4:0]  de_rs1,
  output logic [4:0]  de_rs2
  );

  logic        fe1_exc_r;
  logic [31:0] de_insn;
  always_ff @(posedge clk_core)
    if(~reset_n) begin
      de_valid <= 0;
      fe1_exc_r <= 0;
    end else if(~de_stall | csr_kill) begin
      de_valid <= fe1_valid & ~fe1_stall & ~fe1_exc & ~csr_kill;
      fe1_exc_r <= fe1_exc & ~csr_kill;
      de_pc <= fe1_pc;

      de_insn <= fe1_insn;
    end

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
  assign de_imm = jump ? 4 : imm;

  // register file
  logic [31:0] rf_rdata1, rf_rdata2;
  regfile regfile(
    .clk(clk_core),
    .reset_n(reset_n),

    .rs1(rs1),
    .rdata1(rf_rdata1),

    .rs2(rs2),
    .rdata2(rf_rdata2),

    .wreg(wb_reg),
    .wdata(wb_data),
    .wen(wb_valid)
    );

  always_comb
    if((opcode != BRANCH) & (opcode != STORE))
      de_wb_reg = de_insn[11:7];
    else
      de_wb_reg = 0;

  // forwarding
  assign de_rs1 = rs1;
  assign de_rs2 = rs2;

  logic [31:0] rdata1, rdata2;
  always_comb begin
    if(fwd_rs1.ex & ~jalr)
      rdata1 = ex_fwd_data;
    else if(fwd_rs1.mem0)
      rdata1 = mem0_fwd_data;
    else if(fwd_rs1.mem1)
      rdata1 = mem1_fwd_data;
    else
      rdata1 = rf_rdata1;

    if(fwd_rs2.ex)
      rdata2 = ex_fwd_data;
    else if(fwd_rs2.mem0)
      rdata2 = mem0_fwd_data;
    else if(fwd_rs2.mem1)
      rdata2 = mem1_fwd_data;
    else
      rdata2 = rf_rdata2;
  end

  always_comb begin
    de_rdata1 = (csr & funct3[2]) ? rs1 : rdata1;
    de_rdata2 = rdata2;
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
  always_ff @(posedge clk_core)
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

  always_comb begin
    de_br = opcode == BRANCH;
    de_br_inv = funct3[0];
    de_br_taken = br_take;
    de_br_misalign = misalign;
    de_br_miss_misalign = |br_miss_pc[1:0];
  end

  // control signal decoder
  always_comb begin
    de_use_pc = (opcode == JAL) | (opcode == JALR) | (opcode == AUIPC);
    de_use_imm = ~format.r & (opcode != BRANCH);
    de_data1_sel = csr;
    de_sub_sra = (opcode == OP) & funct7[5];
  end

  logic mul;
  assign mul = (opcode == OP) & funct7[0];
  always_comb begin
    de_op = '{default:0};
    unique0 case(opcode)
      OP, OP_IMM:
        case({mul,funct3})
          'b0000: de_op.add = 1;
          'b0001: de_op.sl = 1;
          'b0010: de_op.slt = 1;
          'b0011: de_op.sltu = 1;
          'b0100: de_op.xor_ = 1;
          'b0101: de_op.sr = 1;
          'b0110: de_op.or_ = 1;
          'b0111: de_op.and_ = 1;
          // M extension.
          'b1000: de_op.mul = 1;
          'b1001: de_op.mulh = 1;
          'b1010: de_op.mulhsu = 1;
          'b1011: de_op.mulhu = 1;
        endcase

      LOAD, STORE: de_op.add = 1;

      LUI: de_op.nop = 1;
      AUIPC: de_op.add = 1;

      JAL, JALR: de_op.add = 1;
      BRANCH:
        unique casez(funct3[2:1])
          'b0?: de_op.seq = 1;
          'b10: de_op.slt = 1;
          'b11: de_op.sltu = 1;
        endcase

      MISC_MEM, SYSTEM: de_op.nop = 1;
    endcase
  end

  always_comb
    // hijack the mem signals for csr accesses
    if(csr) begin
      de_mem_read   <= 1;
      de_mem_write  <= 1;
      // csr_read
      de_mem_extend <= |rd;
      // csr_write
      de_mem_width  <= |rs1 ? funct3[1:0] : 0;
    end else begin
      de_mem_read   <= opcode == LOAD;
      de_mem_write  <= opcode == STORE;
      de_mem_extend <= funct3[2];
      de_mem_width  <= funct3[1:0];
    end

  // stall/valid logic
  logic test_stop;
`ifndef SYNTHESIS
  assign test_stop = de_insn == TEST_MAGIC;
`else
  assign test_stop = 0;
`endif

  logic special, ecall, ebreak, eret;
  assign special = (opcode == SYSTEM) & ~|funct3[1:0];
  assign ecall  = special & (rs2[1:0] == 'b00);
  assign ebreak = special & (rs2[1:0] == 'b01);
  assign eret   = special & (rs2[1:0] == 'b10);

  always_comb begin
    de_exc = fe1_exc_r;
    de_exc_cause = IFAULT;
    if(test_stop)
      de_exc = 0;
    else if(de_valid) begin
      de_exc = 1;
      if(format.invalid)
        // imm = de_insn (in immediate decoder)
        de_exc_cause = IILLEGAL;
      else if(jump & misalign)
        de_exc_cause = IALIGN;
      else if(ebreak)
        de_exc_cause = EBREAK;
      else if(ecall)
        de_exc_cause = MCALL;
      else if(eret)
        de_exc_cause = ERET;
      else
        de_exc = 0;
    end
  end

  logic jalr_stall;
  assign jalr_stall = jalr & fwd_rs1.ex;

  assign de_stall = (de_valid & (ex_stall | test_stop | jalr_stall | fwd_stall)) | (de_exc & ex_stall);

`ifndef SYNTHESIS
  always_ff @(posedge clk_core)
    if(de_stall & ~format.invalid)
      $display("%d: stage_decode: stalling", $stime);
`endif

endmodule
