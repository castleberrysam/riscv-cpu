`timescale 1ns/1ps

`include "defines.svh"

module forward_unit(
  // inputs from decode
  input logic [4:0] de_rs1,
  input logic [4:0] de_rs2,

  // inputs from execute
  input logic       ex_valid,
  input logic       mem_read,
  input logic [4:0] ex_rd,

  // inputs from mem
  input logic       mem_valid,
  input logic       mem_read_r,
  input logic [4:0] mem_rd,

  // outputs to decode
  output logic      fwd_stall,
  output fwd_type_t fwd_rs1,
  output fwd_type_t fwd_rs2
  );

  // FIXME maybe a macro here would help reduce this duplication.
  logic fwd_stall_rs1;
  always_comb begin
    fwd_stall_rs1 = 0;
    fwd_rs1 = '{default:0};

    if(ex_valid & |ex_rd & (ex_rd == de_rs1)) begin
      fwd_stall_rs1 = mem_read;
      fwd_rs1.ex = 1;
    end else if(mem_valid & |mem_rd & (mem_rd == de_rs1)) begin
      fwd_stall_rs1 = mem_read_r;
      fwd_rs1.mem = 1;
    end
  end

  logic fwd_stall_rs2;
  always_comb begin
    fwd_stall_rs2 = 0;
    fwd_rs2 = '{default:0};

    if(ex_valid & |ex_rd & (ex_rd == de_rs2)) begin
      fwd_stall_rs2 = mem_read;
      fwd_rs2.ex = 1;
    end else if(mem_valid & |mem_rd & (mem_rd == de_rs2)) begin
      fwd_stall_rs2 = mem_read_r;
      fwd_rs2.mem = 1;
    end
  end

  assign fwd_stall = fwd_stall_rs1 | fwd_stall_rs2;

endmodule
