`timescale 1ns/1ps
`default_nettype none

module stage_execute(
  input             clk,
  input             reset_n,

  // inputs from decode stage
  input             ex_valid,

  input [31:0]      ex_pc,
  input [31:0]      ex_rdata1,
  input [31:0]      ex_rdata2,
  input [31:0]      ex_imm,

  input             ex_use_pc0,
  input             ex_use_pc1,
  input             ex_use_imm,
  input             ex_sub_sra,
  input [3:0]       ex_op,

  input             mem_read,
  input             mem_write,
  input             mem_extend,
  input [1:0]       mem_width,

  input             mem_jmp,
  input             mem_br,
  input             mem_br_inv,

  input [4:0]       wb_reg,

  // inputs from mem stage
  input             mem_stall,

  // outputs to decode stage
  output            ex_stall,

  // outputs to mem stage
  output reg        mem_valid,

  output reg [31:0] mem_pc,

  output reg [31:0] mem_data0,
  output reg [31:0] mem_data1,

  output reg        mem_read_r,
  output reg        mem_write_r,
  output reg        mem_extend_r,
  output reg [1:0]  mem_width_r,

  output reg        mem_jmp_r,
  output reg        mem_br_r,
  output reg        mem_br_inv_r,

  output reg [4:0]  wb_reg_r
  );

    `include "defines.vh"

    always @(posedge clk)
      if(!mem_stall)
        begin
            mem_pc <= ex_pc;
            mem_read_r <= mem_read;
            mem_write_r <= mem_write;
            mem_extend_r <= mem_extend;
            mem_width_r <= mem_width;
            mem_jmp_r <= mem_jmp;
            mem_br_r <= mem_br;
            mem_br_inv_r <= mem_br_inv;
            wb_reg_r <= wb_reg;
        end

    wire [31:0] op1 = ex_use_pc0 ? ex_pc : ex_rdata1;
    wire [31:0] op2 = mem_jmp ? 32'd4 : (ex_use_imm ? ex_imm : ex_rdata2);

    `ifndef SLOW_MUL
    reg mul_go;
    wire mul_done = 1;
    reg [63:0] mul_result;
    always @(*)
      begin
          mul_go = 1;
          case(ex_op)
            ALUOP_MUL: mul_result = op1 * op2;
            ALUOP_MULH: mul_result = $signed(op1) * $signed(op2);
            ALUOP_MULHSU: mul_result = $signed(op1) * $signed({1'b0,op2});
            ALUOP_MULHU: mul_result = op1 * op2;
            default:
              begin
                  mul_go = 0;
                  mul_result = 32'b0;
              end
          endcase
      end
    `else
    wire mul_sign0 = (ex_op == ALUOP_MUL) | (ex_op == ALUOP_MULH);
    wire mul_sign1 = mul_sign0 | (ex_op == ALUOP_MULHSU);
    wire mul_go = ex_valid & (mul_sign1 | (ex_op == ALUOP_MULHU));
    wire mul_done;
    wire [63:0] mul_result;
    mul_booth mul(
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
    `endif

    always @(posedge clk)
      if(!mem_stall)
        case(ex_op)
          ALUOP_NOP: mem_data0 <= op2;

          ALUOP_ADD: mem_data0 <= op1 + (ex_sub_sra ? -op2 : op2);
          ALUOP_AND: mem_data0 <= op1 & op2;
          ALUOP_OR: mem_data0 <= op1 | op2;
          ALUOP_XOR: mem_data0 <= op1 ^ op2;

          ALUOP_SEQ: mem_data0 <= {31'd0,op1 == op2};
          ALUOP_SLT: mem_data0 <= {31'd0,$signed(op1) < $signed(op2)};
          ALUOP_SLTU: mem_data0 <= {31'd0,op1 < op2};

          ALUOP_SL: mem_data0 <= op1 << op2[4:0];
          ALUOP_SR:
            if(ex_sub_sra)
              mem_data0 <= op1 >>> op2[4:0];
            else
              mem_data0 <= op1 >> op2[4:0];

          ALUOP_MUL: mem_data0 <= mul_result[31:0];
          ALUOP_MULH, ALUOP_MULHSU, ALUOP_MULHU: mem_data0 <= mul_result[63:32];
        endcase

    always @(posedge clk)
      if(!mem_stall)
        if(mem_jmp | mem_br)
          mem_data1 <= ex_imm + (ex_use_pc1 ? ex_pc : ex_rdata1);
        else
          mem_data1 <= ex_rdata2;

    assign ex_stall = ex_valid & (mem_stall | (mul_go & ~mul_done));
    always @(posedge clk)
      if(~reset_n)
        mem_valid <= 0;
      else
        mem_valid <= mem_stall | (ex_valid & ~ex_stall);

endmodule
