`timescale 1ns/1ps

`include "defines.svh"

module stage_fetch1(
  input logic          clk_core,
  input logic          reset_n,

  // fetch0 inputs/outputs
  input logic          fe0_valid,
  output logic         fe1_stall,

  input logic          fe0_specid,
  input logic [31:2]   fe0_read_addr,

  // icache inputs
  input logic          ic_tlb_read_hit,
  input logic          ic_tlb_read_super,
  input logic [28:12]  ic_tlb_read_ppn,
  input logic [7:0]    ic_tlb_read_flags,

  input logic          ic_cam_read_hit,
  input logic [31:0]   ic_cam_read_data,
  input logic [28:12]  ic_cam_lru_tag,
  input logic [1:0]    ic_cam_lru_flags,

  // icache outputs
  output logic         fe1_tlb_read_req,
  output logic [8:0]   fe1_tlb_read_asid,
  output logic [31:12] fe1_tlb_read_addr,

  output logic         fe1_tlb_write_req,
  output logic         fe1_tlb_write_super,
  output logic [31:21] fe1_tlb_write_tag,
  output logic [8:0]   fe1_tlb_write_asid,
  output logic [28:12] fe1_tlb_write_ppn,
  output logic [7:0]   fe1_tlb_write_flags,

  output logic [28:12] fe1_cam_read_tag,

  output logic         fe1_cam_write_req,
  output logic         fe1_cam_write_lru_way,
  output logic [1:0]   fe1_cam_write_offset,

  output logic [31:0]  fe1_cam_write_data,

  output logic [28:12] fe1_cam_write_tag,
  output logic [1:0]   fe1_cam_write_flags,

  output logic         fe1_cam_lru_update,

  // decode inputs/outputs
  output logic         fe1_valid,
  input logic          de_stall,
  output logic         fe1_exc,
  output logic [31:2]  fe1_pc,

  output logic         fe1_specid,
  output logic [31:0]  fe1_insn,

  // execute inputs
  input logic          ex_valid,

  input logic          ex_specid,
  input logic          ex_br_taken,
  input logic          ex_br_ntaken,

  // memory0 inputs/outputs
  input logic          mem0_valid,

  output logic         fe1_mem0_read,
  output logic [28:2]  fe1_mem0_addr,

  // memory1 inputs/outputs
  input logic          mem1_valid_fe1,
  input logic          mem1_stall,
  input logic          mem1_exc,
  input ecause_t       mem1_exc_cause,

  input logic [31:0]   mem1_dout,

  output logic         fe1_mem1_kill,

  // csr inputs
  input logic          csr_kill,

  input logic [31:0]   csr_satp,

  // bus inputs/outputs
  output logic         fe1_cvalid,
  input logic          bmain_cready_fe1,
  output logic         fe1_cmd,
  output logic [28:2]  fe1_addr,

  input logic          bmain_rvalid_fe1,
  output logic         fe1_rready,
  input logic          bmain_rlast,
  input logic [31:0]   bmain_rdata,

  input logic          bmain_error_fe1,
  output logic         fe1_eack
  );

  logic kill;
  assign kill = csr_kill | ((fe1_specid ^ ex_specid) ? ex_br_ntaken : ex_br_taken);
  assign fe1_mem1_kill = kill;

  logic busy, killed;
  always_ff @(posedge clk_core)
    if(~reset_n)
      killed <= 0;
    else if(kill & busy)
      killed <= 1;
    else if(~busy)
      killed <= 0;

  logic valid;
  always_ff @(posedge clk_core)
    if(~reset_n)
      valid <= 0;
    else if(~fe1_stall | ((kill | killed) & ~busy)) begin
      valid <= fe0_valid;
      fe1_specid <= fe0_specid;
      fe1_pc <= fe0_read_addr;
    end

  assign fe1_valid = valid & ~fe1_stall & ~exc & ~(kill | killed);
  assign fe1_exc = exc & ~(kill | killed);

  // tlb state machine
  logic tlb_exc;

  logic fe1_mem1_stall;
  assign fe1_mem1_stall = fe1_mem0_read & mem1_stall;

  struct packed {
    logic idle, fill0, fill1, fill2, fill3;
  } tlb_state, tlb_state_next;

  always_ff @(posedge clk_core)
    if(~reset_n | tlb_exc | kill | killed)
      tlb_state <= '{idle:1,default:0};
    else if(~fe1_mem1_stall)
      tlb_state <= tlb_state_next;

  logic tlb_start_fill;
  assign tlb_start_fill = valid & satp_mode & ~ic_tlb_read_hit;

  logic tlb_stall;
  assign tlb_stall = ~tlb_state.idle | tlb_start_fill;

  logic         satp_mode;
  logic [8:0]   satp_asid;
  logic [28:12] satp_ppn;
  assign satp_mode = csr_satp[31];
  assign satp_asid = csr_satp[30:22];
  assign satp_ppn  = csr_satp[16:0];

  assign fe1_tlb_read_asid = satp_asid;
  assign fe1_tlb_read_addr = fe1_pc[31:12];
  assign fe1_tlb_write_asid = satp_asid;
  assign fe1_tlb_write_ppn = pte.ppn;
  assign fe1_tlb_write_flags = pte.flags;
  assign fe1_tlb_write_tag = fe1_pc[31:21];

  pte_t pte;
  assign pte = pte_t'(mem1_dout);

  logic pte_valid, pte_leaf;
  assign pte_valid = pte.flags.v & (pte.flags.r | ~pte.flags.w);
  assign pte_leaf = pte.flags.r | pte.flags.w | pte.flags.x;

  always_comb begin
    // set default values of outputs
    tlb_state_next = tlb_state;
    tlb_exc = 0;

    fe1_tlb_read_req = 0;

    fe1_tlb_write_req = 0;
    fe1_tlb_write_super = 0;

    fe1_mem0_read = 0;
    fe1_mem0_addr = '0;

    unique case(1)
      tlb_state.idle:
        // tlb miss?
        if(tlb_start_fill)
          tlb_state_next = '{fill0:1,default:0};

      tlb_state.fill0: begin
        // read first-level PTE
        fe1_mem0_read = ~kill;
        fe1_mem0_addr = {satp_ppn,fe1_pc[31:22]};

        tlb_state_next = '{fill1:1,default:0};
      end

      tlb_state.fill1: begin
        fe1_tlb_write_super = 1;
        fe1_mem0_addr = {pte.ppn,fe1_pc[21:12]};

        if(~mem1_valid_fe1)
          // wait for request to complete
          ;
        else if(mem1_exc | ~pte_valid)
          // raise exception (access fault/invalid PTE)
          tlb_exc = 1;
        else if(~pte_leaf) begin
          // read second-level PTE
          fe1_mem0_read = ~kill;

          tlb_state_next = '{fill2:1,default:0};
        end else if(|pte.ppn[9:0])
          // raise exception (misaligned superpage)
          tlb_exc = 1;
        else begin
          // everything checks out, write superpage to the tlb
          fe1_tlb_write_req = 1;

          tlb_state_next = '{fill3:1,default:0};
        end
      end

      tlb_state.fill2:
        if(~mem1_valid_fe1)
          // wait for request to complete
          ;
        else if(mem1_exc | ~pte_valid | ~pte_leaf)
          // raise exception (access fault/invalid PTE)
          tlb_exc = 1;
        else begin
          // everything checks out, write page to the tlb
          fe1_tlb_write_req = 1;

          tlb_state_next = '{fill3:1,default:0};
        end

      tlb_state.fill3: begin
        // redo the initial access
        fe1_tlb_read_req = 1;

        tlb_state_next = '{idle:1,default:0};
      end
    endcase
  end

  // cam state machine
  logic cam_exc;
  assign cam_exc = bmain_error_fe1;
  assign fe1_eack = bmain_error_fe1;

  logic bus_stall_cmd, bus_stall_rdata, bus_stall;
  assign bus_stall_cmd = fe1_cvalid & ~bmain_cready_fe1;
  assign bus_stall_rdata = fe1_rready & ~bmain_rvalid_fe1;
  assign bus_stall = bus_stall_cmd | bus_stall_rdata;

  logic bus_beat_rdata;
  assign bus_beat_rdata = fe1_rready & bmain_rvalid_fe1;

  struct packed {
    logic idle, fill0, fill1;
  } cam_state, cam_state_next;

  logic fe1_insn_sel, fe1_insn_sel_r;
  always_ff @(posedge clk_core)
    if(~reset_n | cam_exc) begin
      cam_state <= '{idle:1,default:0};
      fe1_insn_sel_r <= 0;
    end else if(~bus_stall) begin
      cam_state <= cam_state_next;
      fe1_insn_sel_r <= fe1_insn_sel;
    end

  logic [3:2] cam_line_offset;
  always_ff @(posedge clk_core)
    if(~reset_n | cam_exc)
      cam_line_offset <= '0;
    else if(bus_beat_rdata)
      cam_line_offset <= cam_line_offset + 1;

  logic        cam_insn_wen;
  logic [31:0] cam_insn;
  always_ff @(posedge clk_core)
    if(cam_insn_wen)
      cam_insn <= bmain_rdata;

  logic cam_start_fill;
  assign cam_start_fill = valid & ~kill & (~satp_mode | ic_tlb_read_hit) & ~ic_cam_read_hit & ~fe1_insn_sel_r;

  logic cam_stall;
  assign cam_stall = bus_stall | ~cam_state.idle | cam_start_fill;

  assign fe1_cmd = 1;
  assign fe1_addr = {fe1_cam_read_tag,fe1_pc[11:4],2'b0};

  assign fe1_cam_read_tag = satp_mode ? ic_tlb_read_ppn : fe1_pc[28:12];
  assign fe1_cam_write_offset = cam_line_offset;
  assign fe1_cam_write_data = bmain_rdata;
  assign fe1_cam_write_tag = fe1_cam_read_tag;
  assign fe1_cam_write_flags = 'b01;

  assign fe1_insn = fe1_insn_sel_r ? cam_insn : ic_cam_read_data;

  always_comb begin
    // set default values of outputs
    cam_state_next = cam_state;

    fe1_cam_write_req = 0;
    fe1_cam_write_lru_way = 0;
    fe1_cam_lru_update = 0;

    fe1_cvalid = 0;
    fe1_rready = 0;

    cam_insn_wen = 0;
    fe1_insn_sel = 0;

    unique case(1)
      cam_state.idle: begin
        fe1_cam_lru_update = 1;

        // tlb hit, cam miss?
        if(cam_start_fill)
          cam_state_next = '{fill0:1,default:0};
      end

      cam_state.fill0: begin
        // initiate bus read
        fe1_cvalid = 1;
        cam_state_next = '{fill1:1,default:0};
      end

      cam_state.fill1: begin
        // continue bus read
        fe1_rready = 1;

        // write word to cache, mark line valid
        fe1_cam_write_req = 1;
        fe1_cam_write_lru_way = 1;

        // is this the desired word?
        if(cam_line_offset == fe1_pc[3:2])
          // capture instruction
          cam_insn_wen = 1;

        // select captured instruction
        fe1_insn_sel = 1;

        // last word?
        if(cam_line_offset == 'd3) begin
          // update lru bits
          fe1_cam_lru_update = 1;

          cam_state_next = '{idle:1,default:0};
        end
       end
    endcase
  end

  logic exc;
  assign busy = cam_stall;
  assign fe1_stall = (valid & (tlb_stall | cam_stall | de_stall)) | (exc & de_stall);
  assign exc = tlb_exc | cam_exc;

endmodule
