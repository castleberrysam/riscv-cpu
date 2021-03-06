`timescale 1ns/1ps

`include "defines.svh"

module dcache(
  input logic          clk_core,
  input logic          reset_n,

  // memory0 inputs
  input logic          mem0_dc_read,
  input logic          mem0_dc_trans,
  input logic [8:0]    mem0_dc_asid,
  input logic [31:2]   mem0_dc_addr,

  // memory1 inputs
  input logic          mem1_tlb_write_req,
  input logic          mem1_tlb_write_super,
  input logic [31:21]  mem1_tlb_write_tag,
  input logic [8:0]    mem1_tlb_write_asid,
  input logic [28:12]  mem1_tlb_write_ppn,
  input logic [7:0]    mem1_tlb_write_flags,

  input logic          mem1_cam_read_req,
  input logic [11:2]   mem1_cam_read_index,
  input logic [28:12]  mem1_cam_read_tag,

  input logic          mem1_cam_write_req,
  input logic          mem1_cam_write_lru_way,
  input logic [1:0]    mem1_cam_write_offset,

  input logic [31:0]   mem1_cam_write_data,
  input logic [3:0]    mem1_cam_write_mask,

  input logic [28:12]  mem1_cam_write_tag,
  input logic [1:0]    mem1_cam_write_flags,

  input logic          mem1_cam_lru_update,

  // memory1 outputs
  output logic         dc_tlb_read_hit,
  output logic         dc_tlb_read_super,
  output logic [28:12] dc_tlb_read_ppn,
  output logic [7:0]   dc_tlb_read_flags,

  output logic         dc_cam_read_hit,
  output logic [31:0]  dc_cam_read_data,
  output logic [28:12] dc_cam_lru_tag,
  output logic [1:0]   dc_cam_lru_flags
  );

  tlb #("dcache") tlb(
    .clk(clk_core),
    .reset_n(reset_n),

    // read inputs
    .read_req(mem0_dc_read & mem0_dc_trans),
    .read_asid(mem0_dc_asid),
    .read_addr(mem0_dc_addr[31:12]),

    // read outputs
    .read_hit(dc_tlb_read_hit),
    .read_super(dc_tlb_read_super),

    .read_ppn(dc_tlb_read_ppn),
    .read_flags(dc_tlb_read_flags),

    // write inputs
    .write_req(mem1_tlb_write_req),
    .write_super(mem1_tlb_write_super),

    .write_tag(mem1_tlb_write_tag),
    .write_asid(mem1_tlb_write_asid),
    .write_ppn(mem1_tlb_write_ppn),
    .write_flags(mem1_tlb_write_flags)
    );

  cam #("dcache") cam(
    .clk(clk_core),
    .reset_n(reset_n),

    // read inputs
    .read_req(mem0_dc_read | mem1_cam_read_req),
    .read_index(mem1_cam_read_req ? mem1_cam_read_index : mem0_dc_addr[11:2]),
    .read_tag(mem1_cam_read_tag),

    // read outputs
    .read_hit(dc_cam_read_hit),
    .read_data(dc_cam_read_data),

    // write inputs
    .write_req(mem1_cam_write_req),
    .write_lru_way(mem1_cam_write_lru_way),
    .write_offset(mem1_cam_write_offset),

    .write_data(mem1_cam_write_data),
    .write_mask(mem1_cam_write_mask),

    .write_tag(mem1_cam_write_tag),
    .write_flags(mem1_cam_write_flags),

    // lru
    .lru_update(mem1_cam_lru_update),
    .lru_tag(dc_cam_lru_tag),
    .lru_flags(dc_cam_lru_flags)
    );

endmodule
