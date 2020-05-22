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
  ALUOP_SR   = 4'd9;

// File descriptors
localparam
  STDIN  = 32'h80000000,
  STDOUT = 32'h80000001,
  STDERR = 32'h80000002;
