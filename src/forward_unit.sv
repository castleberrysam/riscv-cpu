`timescale 1ns/1ps

`include "defines.svh"

module forward_unit(
  // inputs from decode
  input logic [4:0] de_rs1,
  input logic [4:0] de_rs2,

  // execute inputs
  input logic       ex_valid,
  input logic       ex_mem_read,
  input logic [4:0] ex_wb_reg,

  // memory0 inputs
  input logic       mem0_valid,
  input logic       mem0_read,
  input logic [4:0] mem0_wb_reg,

  // memory1 inputs
  input logic       mem1_valid_wb,
  input logic       mem1_read,
  input logic [4:0] mem1_wb_reg,

  // outputs to decode
  output logic      fwd_stall,
  output fwd_type_t fwd_rs1,
  output fwd_type_t fwd_rs2
  );

  logic fwd_stall_rs1;
  always_comb begin
    fwd_stall_rs1 = 0;
    fwd_rs1 = '{default:0};

    if(ex_valid & |ex_wb_reg & (ex_wb_reg == de_rs1)) begin
      fwd_stall_rs1 = ex_mem_read;
      fwd_rs1.ex = 1;
    end else if(mem0_valid & |mem0_wb_reg & (mem0_wb_reg == de_rs1)) begin
      fwd_stall_rs1 = mem0_read;
      fwd_rs1.mem0 = 1;
    end else if(mem1_valid_wb & |mem1_wb_reg & (mem1_wb_reg == de_rs1)) begin
      fwd_stall_rs1 = mem1_read;
      fwd_rs1.mem1 = 1;
    end
  end

  logic fwd_stall_rs2;
  always_comb begin
    fwd_stall_rs2 = 0;
    fwd_rs2 = '{default:0};

    if(ex_valid & |ex_wb_reg & (ex_wb_reg == de_rs2)) begin
      fwd_stall_rs2 = ex_mem_read;
      fwd_rs2.ex = 1;
    end else if(mem0_valid & |mem0_wb_reg & (mem0_wb_reg == de_rs2)) begin
      fwd_stall_rs2 = mem0_read;
      fwd_rs2.mem0 = 1;
    end else if(mem1_valid_wb & |mem1_wb_reg & (mem1_wb_reg == de_rs2)) begin
      fwd_stall_rs2 = mem1_read;
      fwd_rs2.mem1 = 1;
    end
  end

  assign fwd_stall = fwd_stall_rs1 | fwd_stall_rs2;

endmodule
