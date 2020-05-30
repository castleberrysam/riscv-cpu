// Opcode definitions
localparam
  OP_LOAD       = 5'b00000,
  OP_LOAD_FP    = 5'b00001,
  OP_CUSTOM_0   = 5'b00010,
  OP_MISC_MEM   = 5'b00011,
  OP_OP_IMM     = 5'b00100,
  OP_AUIPC      = 5'b00101,
  OP_OP_IMM_32  = 5'b00110,
  OP_48_0       = 5'b00111,
                    
  OP_STORE      = 5'b01000,
  OP_STORE_FP   = 5'b01001,
  OP_CUSTOM_1   = 5'b01010,
  OP_AMO        = 5'b01011,
  OP_OP         = 5'b01100,
  OP_LUI        = 5'b01101,
  OP_OP_32      = 5'b01110,
  OP_64         = 5'b01111,
                    
  OP_MADD       = 5'b10000,
  OP_MSUB       = 5'b10001,
  OP_NMSUB      = 5'b10010,
  OP_NMADD      = 5'b10011,
  OP_OP_FP      = 5'b10100,
  OP_RESERVED_0 = 5'b10101,
  OP_CUSTOM_2   = 5'b10110,
  OP_48_1       = 5'b10111,
                    
  OP_BRANCH     = 5'b11000,
  OP_JALR       = 5'b11001,
  OP_RESERVED_1 = 5'b11010,
  OP_JAL        = 5'b11011,
  OP_SYSTEM     = 5'b11100,
  OP_RESERVED_2 = 5'b11101,
  OP_CUSTOM_3   = 5'b11110,
  OP_80         = 5'b11111;

// ALU operations
localparam
  ALUOP_NOP  = 4'd0,
             
  ALUOP_ADD  = 4'd1,
  ALUOP_AND  = 4'd2,
  ALUOP_OR   = 4'd3,
  ALUOP_XOR  = 4'd4,
             
  ALUOP_SEQ  = 4'd5,
  ALUOP_SLT  = 4'd6,
  ALUOP_SLTU = 4'd7,
             
  ALUOP_SL   = 4'd8,
  ALUOP_SR   = 4'd9,

  ALUOP_MUL    = 4'd10,
  ALUOP_MULH   = 4'd11,
  ALUOP_MULHSU = 4'd12,
  ALUOP_MULHU  = 4'd13;

// File descriptors
localparam
  STDIN  = 32'h80000000,
  STDOUT = 32'h80000001,
  STDERR = 32'h80000002;

// Forwarding
localparam
  NOT_FORWARDING    = 2'd0,
  FORWARDING_EX = 2'd1,
  FORWARDING_MEM = 2'd2;

// Utility functions
function [8*5:1] abi_name(
  input logic [4:0] regnum
  );

  case(regnum)
    5'd0: abi_name = "zero";
    5'd1: abi_name = "ra";
    5'd2: abi_name = "sp";
    5'd3: abi_name = "gp";
    5'd4: abi_name = "tp";
    5'd5: abi_name = "t0";
    5'd6: abi_name = "t1";
    5'd7: abi_name = "t2";
    5'd8: abi_name = "fp";
    5'd9: abi_name = "s1";
    5'd10: abi_name = "a0";
    5'd11: abi_name = "a1";
    5'd12: abi_name = "a2";
    5'd13: abi_name = "a3";
    5'd14: abi_name = "a4";
    5'd15: abi_name = "a5";
    5'd16: abi_name = "a6";
    5'd17: abi_name = "a7";
    5'd18: abi_name = "s2";
    5'd19: abi_name = "s3";
    5'd20: abi_name = "s4";
    5'd21: abi_name = "s5";
    5'd22: abi_name = "s6";
    5'd23: abi_name = "s7";
    5'd24: abi_name = "s8";
    5'd25: abi_name = "s9";
    5'd26: abi_name = "s10";
    5'd27: abi_name = "s11";
    5'd28: abi_name = "t3";
    5'd29: abi_name = "t4";
    5'd30: abi_name = "t5";
    5'd31: abi_name = "t6";
  endcase

endfunction
