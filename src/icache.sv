`timescale 1ns/1ps

`include "defines.svh"

module icache(
  input logic          clk_core,
  input logic          reset_n,

  // inputs from fetch0
  input logic          fe0_read_req,
  input logic [8:0]    fe0_read_asid,
  input logic [31:2]   fe0_read_addr,

  // inputs from fetch1
  input logic          fe1_tlb_read_req,
  input logic [8:0]    fe1_tlb_read_asid,
  input logic [31:12]  fe1_tlb_read_addr,

  input logic          fe1_tlb_write_req,
  input logic          fe1_tlb_write_super,
  input logic [31:21]  fe1_tlb_write_tag,
  input logic [8:0]    fe1_tlb_write_asid,
  input logic [28:12]  fe1_tlb_write_ppn,
  input logic [7:0]    fe1_tlb_write_flags,

  input logic [28:12]  fe1_cam_read_tag,

  input logic          fe1_cam_write_req,
  input logic          fe1_cam_write_lru_way,
  input logic [1:0]    fe1_cam_write_offset,

  input logic [31:0]   fe1_cam_write_data,

  input logic [28:12]  fe1_cam_write_tag,
  input logic [1:0]    fe1_cam_write_flags,

  input logic          fe1_cam_lru_update,

  // outputs to fetch1
  output logic         ic_tlb_read_hit,
  output logic         ic_tlb_read_super,
  output logic [28:12] ic_tlb_read_ppn,
  output logic [7:0]   ic_tlb_read_flags,

  output logic         ic_cam_read_hit,
  output logic [31:0]  ic_cam_read_data,
  output logic [28:12] ic_cam_lru_tag,
  output logic [1:0]   ic_cam_lru_flags
  );

  tlb #("icache") tlb(
    .clk(clk_core),
    .reset_n(reset_n),

    // read inputs
    .read_req(fe0_read_req | fe1_tlb_read_req),
    .read_asid(fe0_read_req ? fe0_read_asid : fe1_tlb_read_asid),
    .read_addr(fe0_read_req ? fe0_read_addr[31:12] : fe1_tlb_read_addr),

    // read outputs
    .read_hit(ic_tlb_read_hit),
    .read_super(ic_tlb_read_super),

    .read_ppn(ic_tlb_read_ppn),
    .read_flags(ic_tlb_read_flags),

    // write inputs
    .write_req(fe1_tlb_write_req),
    .write_super(fe1_tlb_write_super),

    .write_tag(fe1_tlb_write_tag),
    .write_asid(fe1_tlb_write_asid),
    .write_ppn(fe1_tlb_write_ppn),
    .write_flags(fe1_tlb_write_flags)
    );

  cam #("icache") cam(
    .clk(clk_core),
    .reset_n(reset_n),

    // read inputs
    .read_req(fe0_read_req),
    .read_index(fe0_read_addr[11:2]),
    .read_tag(fe1_cam_read_tag),

    // read outputs
    .read_hit(ic_cam_read_hit),
    .read_data(ic_cam_read_data),

    // write inputs
    .write_req(fe1_cam_write_req),
    .write_lru_way(fe1_cam_write_lru_way),
    .write_offset(fe1_cam_write_offset),

    .write_data(fe1_cam_write_data),
    .write_mask('1),

    .write_tag(fe1_cam_write_tag),
    .write_flags(fe1_cam_write_flags),

    // lru
    .lru_update(fe1_cam_lru_update),
    .lru_tag(ic_cam_lru_tag),
    .lru_flags(ic_cam_lru_flags)
    );

endmodule
