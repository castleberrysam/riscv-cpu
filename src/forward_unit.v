`timescale 1ns/1ps
`default_nettype none

module forward_unit(
  // inputs from decode
  input wire [4:0] de_rs1,
  input wire [4:0] de_rs2,

  // inputs from execute
  input wire       ex_valid,
  input wire       mem_read,
  input wire [4:0] ex_rd,

  // inputs from mem
  input wire       mem_valid,
  input wire       mem_read_r,
  input wire [4:0] mem_rd,

  // outputs to decode
  output wire      load_stall,

  output reg [1:0] forward_rs1,
  output reg [1:0] forward_rs2
  );

    `include "defines.vh"

    // FIXME maybe a macro here would help reduce this duplication.
    reg load_stall_rs1;
    always @(*)
      begin
          load_stall_rs1 = 0;
          forward_rs1 = NOT_FORWARDING;

          if(ex_valid & |ex_rd & (ex_rd == de_rs1))
            begin
                load_stall_rs1 = mem_read;
                forward_rs1 = FORWARDING_EX;
            end
          else if(mem_valid & |mem_rd & (mem_rd == de_rs1))
            begin
                load_stall_rs1 = mem_read_r;
                forward_rs1 = FORWARDING_MEM;
            end
      end

    reg load_stall_rs2;
    always @(*)
      begin
          load_stall_rs2 = 0;
          forward_rs2 = NOT_FORWARDING;

          if(ex_valid & |ex_rd & (ex_rd == de_rs2))
            begin
                load_stall_rs2 = mem_read;
                forward_rs2 = FORWARDING_EX;
            end
          else if(mem_valid & |mem_rd & (mem_rd == de_rs2))
            begin
                load_stall_rs2 = mem_read_r;
                forward_rs2 = FORWARDING_MEM;
            end
      end

    assign load_stall = load_stall_rs1 | load_stall_rs2;

endmodule
