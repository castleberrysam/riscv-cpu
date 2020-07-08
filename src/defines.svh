`ifndef _DEFINES_
`define _DEFINES_

// Test magic
localparam
  TEST_MAGIC = 'hdecafbad;

// Opcode definitions
typedef enum logic [4:0] {
  LOAD     = 'b00000,
  MISC_MEM = 'b00011,
  OP_IMM   = 'b00100,
  AUIPC    = 'b00101,
  STORE    = 'b01000,
  OP       = 'b01100,
  LUI      = 'b01101,
  BRANCH   = 'b11000,
  JALR     = 'b11001,
  JAL      = 'b11011,
  SYSTEM   = 'b11100
} opcode_t;

// ALU operations
typedef struct packed {
  logic nop;
  logic add, and_, or_, xor_;
  logic seq, slt, sltu;
  logic sl, sr;
  logic mul, mulh, mulhsu, mulhu;
} aluop_t;

// File descriptors
localparam
  STDIN  = 32'h80000000,
  STDOUT = 32'h80000001,
  STDERR = 32'h80000002;

// Exceptions
typedef enum logic [4:0] {
  IALIGN   = 0,
  IFAULT   = 1,
  IILLEGAL = 2,
  EBREAK   = 3,
  LALIGN   = 4,
  LFAULT   = 5,
  SALIGN   = 6,
  SFAULT   = 7,
  UCALL    = 8,
  SCALL    = 9,

  MCALL    = 11,
  IPFAULT  = 12,
  LPFAULT  = 13,

  SPFAULT  = 15,

  // custom use values
  ERET     = 24,
  FLUSH    = 25
} ecause_t;

// Forwarding
typedef struct packed {
  logic ex, mem0, mem1;
} fwd_type_t;

// Virtual memory
typedef struct packed {
  logic d, a, g, u, x, w, r, v;
} pte_flags_t;

typedef struct packed {
  logic [4:0]  _unused;
  logic [16:0] ppn;
  logic [1:0]  rsw;
  pte_flags_t  flags;
} pte_t;

// Utility
string abi_names[32] = '{
  "zero",
  "ra",
  "sp",
  "gp",
  "tp",
  "t0",
  "t1",
  "t2",
  "fp",
  "s1",
  "a0",
  "a1",
  "a2",
  "a3",
  "a4",
  "a5",
  "a6",
  "a7",
  "s2",
  "s3",
  "s4",
  "s5",
  "s6",
  "s7",
  "s8",
  "s9",
  "s10",
  "s11",
  "t3",
  "t4",
  "t5",
  "t6"
};

`endif
