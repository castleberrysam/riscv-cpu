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

  input logic [28:12]  fe1_cam_read_tag_in,

  input logic [11:2]   fe1_cam_write_index,

  input logic          fe1_cam_write_req_data,
  input logic [31:0]   fe1_cam_write_data,

  input logic          fe1_cam_write_req_tag_flags,
  input logic [28:12]  fe1_cam_write_tag,
  input logic [1:0]    fe1_cam_write_flags,

  // outputs to fetch1
  output logic         ic_tlb_read_hit,
  output logic         ic_tlb_read_super,
  output logic [28:12] ic_tlb_read_ppn,
  output logic [7:0]   ic_tlb_read_flags,

  output logic         ic_cam_read_hit,
  output logic [28:12] ic_cam_read_tag_out,
  output logic [31:0]  ic_cam_read_data,
  output logic [1:0]   ic_cam_read_flags
  );

  tlb tlb(
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

  cam cam(
    .clk(clk_core),
    .reset_n(reset_n),

    // read inputs
    .read_req(fe0_read_req),
    .read_index(fe0_read_addr[11:2]),
    .read_tag_in(fe1_cam_read_tag_in),

    // read outputs
    .read_hit(ic_cam_read_hit),
    .read_tag_out(ic_cam_read_tag_out),
    .read_data(ic_cam_read_data),
    .read_flags(ic_cam_read_flags),

    // write inputs
    .write_index(fe1_cam_write_index),

    .write_req_data(fe1_cam_write_req_data),
    .write_data(fe1_cam_write_data),
    .write_mask('1),

    .write_req_tag_flags(fe1_cam_write_req_tag_flags),
    .write_tag(fe1_cam_write_tag),
    .write_flags(fe1_cam_write_flags)
    );

endmodule
