`timescale 1ns/1ps
`default_nettype none

module forward_unit(
  input [4:0]  de_rs1,
  input [4:0]  de_rs2,
  input [4:0]  ex_rd,
  input [4:0]  mem_rd,
  input        ex_wen,
  input        mem_wen,

  output [1:0] forward_rs1,
  output [1:0] forward_rs2
  );
    `include "defines.vh"
    // FIXME maybe a macro here would help reduce this duplication.
    assign forward_rs1 = (ex_wen & (ex_rd == de_rs1)) ?
                         FORWARDING_EX :
                         (mem_wen & (mem_rd == de_rs1)) ?
                         FORWARDING_MEM :
                         NOT_FORWARDING;

    assign forward_rs2 = (ex_wen & (ex_rd == de_rs2)) ?
                         FORWARDING_EX :
                         (mem_wen & (mem_rd == de_rs2)) ?
                         FORWARDING_MEM :
                         NOT_FORWARDING;

endmodule
