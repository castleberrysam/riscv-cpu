`timescale 1ns/1ps

`include "defines.svh"

module stage_fetch1(
  input logic          clk_core,
  input logic          reset_n,

  // fetch0 inputs/outputs
  input logic          fe0_valid,
  output logic         fe1_stall,

  input logic [31:2]   fe0_read_addr,

  // icache inputs
  input logic          ic_tlb_read_hit,
  input logic          ic_tlb_read_super,
  input logic [28:12]  ic_tlb_read_ppn,
  input logic [7:0]    ic_tlb_read_flags,

  input logic          ic_cam_read_hit,
  input logic [28:12]  ic_cam_read_tag_out,
  input logic [31:0]   ic_cam_read_data,
  input logic [1:0]    ic_cam_read_flags,

  // icache outputs
  output logic         fe1_tlb_write_req,
  output logic         fe1_tlb_write_super,
  output logic [31:21] fe1_tlb_write_tag,
  output logic [8:0]   fe1_tlb_write_asid,
  output logic [28:12] fe1_tlb_write_ppn,
  output logic [7:0]   fe1_tlb_write_flags,

  output logic [28:12] fe1_cam_read_tag_in,

  output logic         fe1_cam_read_req,
  output logic [11:2]  fe1_cam_read_index,

  output logic [11:2]  fe1_cam_write_index,

  output logic         fe1_cam_write_req_data,
  output logic [31:0]  fe1_cam_write_data,

  output logic         fe1_cam_write_req_tag_flags,
  output logic [28:12] fe1_cam_write_tag,
  output logic [1:0]   fe1_cam_write_flags,

  // decode inputs/outputs
  input logic          de_valid,
  
  output logic         fe1_valid,
  input logic          de_stall,
  output logic         fe1_exc,
  output logic [31:2]  fe1_pc,

  output logic [31:0]  fe1_insn,

  // execute inputs
  input logic          ex_valid,

  // memory0 inputs/outputs
  input logic          mem0_valid,

  output logic         fe1_mem0_read,
  output logic [28:2]  fe1_mem0_addr,

  // memory1 inputs
  input logic          mem1_valid_fe1,
  input logic          mem1_stall,
  input logic          mem1_exc,
  input ecause_t       mem1_exc_cause,

  input logic [31:0]   mem1_dout,

  // csr inputs
  input logic          csr_kill_setpc,

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

  always_ff @(posedge clk_core)
    if(~reset_n)
      fe1_valid <= 0;
    else if(~fe1_stall) begin
      fe1_valid <= fe0_valid;
      fe1_pc <= fe0_read_addr;
    end

  // tlb state machine
  struct packed {
    logic idle, fill0, fill1;
  } tlb_state, tlb_state_next;

  always_ff @(posedge clk_core)
    if(~reset_n)
      tlb_state <= '{idle:1,default:0};
    else if(csr_kill_setpc)
      tlb_state <= '{idle:1,default:0};
    else
      tlb_state <= tlb_state_next;

  logic tlb_stall;
  assign tlb_stall = ~csr_kill_setpc & ~tlb_state_next.idle;

  logic         satp_mode;
  logic [8:0]   satp_asid;
  logic [28:12] satp_ppn;
  assign satp_mode = csr_satp[31];
  assign satp_asid = csr_satp[30:22];
  assign satp_ppn  = csr_satp[16:0];

  assign fe1_tlb_write_asid = satp_asid;

  pte_t pte;
  assign pte = pte_t'(mem1_dout);

  logic pte_valid, pte_leaf;
  assign pte_valid = pte.flags.v & (pte.flags.r | ~pte.flags.w);
  assign pte_leaf = pte.flags.r | pte.flags.w | pte.flags.x;

  logic tlb_exc;
  always_comb begin
    // set default values of outputs
    tlb_state_next = tlb_state;
    tlb_exc = 0;

    fe1_tlb_write_req = 0;
    fe1_tlb_write_super = 0;
    fe1_tlb_write_tag = 0;
    fe1_tlb_write_ppn = 0;
    fe1_tlb_write_flags = 0;

    fe1_mem0_read = 0;
    fe1_mem0_addr = '0;

    unique case(1)
      tlb_state.idle:
        // tlb miss?
        if(fe1_valid & satp_mode & ~ic_tlb_read_hit) begin
          // read first-level PTE
          fe1_mem0_read = 1;
          fe1_mem0_addr = {satp_ppn,fe1_pc[31:22]};
          tlb_state_next = '{fill0:1,default:0};
        end

      tlb_state.fill0:
        if(~mem1_valid_fe1 | mem1_stall)
          // wait for request to complete
          ;
        else if(mem1_exc | ~pte_valid) begin
          // raise exception (access fault/invalid PTE)
          tlb_exc = 1;
          tlb_state_next = '{idle:1,default:0};
        end else if(~pte_leaf) begin
          // read second-level PTE
          fe1_mem0_read = 1;
          fe1_mem0_addr = {pte.ppn,fe1_pc[21:12]};
          tlb_state_next = '{fill1:1,default:0};
        end else if(|pte.ppn[9:0]) begin
          // raise exception (misaligned superpage)
          tlb_exc = 1;
          tlb_state_next = '{idle:1,default:0};
        end else begin
          // everything checks out, write superpage to the tlb
          fe1_tlb_write_req = 1;
          fe1_tlb_write_super = 1;
          fe1_tlb_write_ppn = pte.ppn;
          fe1_tlb_write_flags = pte.flags;

          tlb_state_next = '{idle:1,default:0};
        end

      tlb_state.fill1:
        if(~mem1_valid_fe1 | mem1_stall)
          // wait for request to complete
          ;
        else if(mem1_exc | ~pte_valid | pte_leaf) begin
          // raise exception (access fault/invalid PTE)
          tlb_exc = 1;
          tlb_state_next = '{idle:1,default:0};
        end else begin
          // everything checks out, write page to the tlb
          fe1_tlb_write_req = 1;
          fe1_tlb_write_tag = fe1_pc[31:21];
          fe1_tlb_write_ppn = pte.ppn;
          fe1_tlb_write_flags = pte.flags;

          tlb_state_next = '{idle:1,default:0};
        end
    endcase
  end

  // cam state machine
  assign fe1_eack = bmain_error_fe1;

  logic bus_stall_cmd, bus_stall_rdata, bus_stall;
  assign bus_stall_cmd = fe1_cvalid & ~bmain_cready_fe1;
  assign bus_stall_rdata = fe1_rready & ~bmain_rvalid_fe1;
  assign bus_stall = bus_stall_cmd | bus_stall_rdata;

  struct packed {
    logic idle, evict, fill0, fill1;
  } cam_state, cam_state_next;

  always_ff @(posedge clk_core)
    if(~reset_n)
      cam_state <= '{idle:1,default:0};
    else if(bmain_error_fe1)
      cam_state <= '{idle:1,default:0};
    else if(~bus_stall)
      cam_state <= cam_state_next;

  logic cam_stall;
  assign cam_stall = bus_stall | ~cam_state_next.idle;

  logic         cam_tlb_hit;
  logic [28:12] cam_tlb_ppn;
  logic [7:0]   cam_tlb_flags;
  always_comb begin
    cam_tlb_hit = ic_tlb_read_hit | fe1_tlb_write_req;
    if(fe1_tlb_write_req) begin
      cam_tlb_ppn = fe1_tlb_write_ppn;
      cam_tlb_flags = fe1_tlb_write_flags;
    end else begin
      cam_tlb_ppn = ic_tlb_read_ppn;
      cam_tlb_flags = ic_tlb_read_flags;
    end
  end

  assign fe1_cam_read_tag_in = satp_mode ? cam_tlb_ppn : fe1_pc[28:12];

  logic [3:2] cam_line_offset, cam_line_offset_next;
  always_comb
    unique case(1)
      cam_state_next.evict: cam_line_offset_next = fe1_pc[3:2] + 1;
      cam_state_next.fill1: cam_line_offset_next = fe1_pc[3:2];
      default: cam_line_offset_next = cam_line_offset + 1;
    endcase
  always_ff @(posedge clk_core)
    if(~bus_stall_rdata)
      cam_line_offset <= cam_line_offset_next;

  logic cam_insn_wen;
  logic [31:0] cam_insn, cam_insn_next;
  always_ff @(posedge clk_core)
    if(cam_insn_wen)
      cam_insn <= cam_insn_next;

  logic cam_exc;
  always_comb begin
    // set default values of outputs
    cam_state_next = cam_state;
    cam_exc = 0;

    fe1_cam_read_req = 0;
    fe1_cam_read_index = 0;

    fe1_cam_write_index = 0;

    fe1_cam_write_req_data = 0;
    fe1_cam_write_data = 0;

    fe1_cam_write_req_tag_flags = 0;
    fe1_cam_write_tag = 0;
    fe1_cam_write_flags = 0;

    fe1_insn = 0;

    cam_insn_wen = 0;
    cam_insn_next = 0;

    fe1_cvalid = 0;
    fe1_cmd = 0;
    fe1_addr = '0;

    fe1_rready = 0;

    // fe1_wvalid = 0;
    // fe1_wlast = 0;
    // fe1_wdata = '0;
    // fe1_wmask = '0;

    unique case(1)
      cam_state.idle: begin
        // tlb hit, cam miss?
        if(fe1_valid & ~csr_kill_setpc & (~satp_mode | cam_tlb_hit) & ~ic_cam_read_hit)
          // need to evict?
          // if(ic_cam_read_flags[0] & ic_cam_read_flags[1]) begin
          //   // initiate bus write
          //   fe1_cvalid = 1;
          //   fe1_cmd = 0;
          //   fe1_addr = {ic_cam_read_tag_out,fe1_pc[11:2]};

          //   fe1_wvalid = 1;
          //   fe1_wlast = 0;
          //   fe1_wdata = ic_cam_read_data;
          //   fe1_wmask = '1;

          //   // read word from cache
          //   fe1_cam_read_req = ~bus_stall_wdata;
          //   fe1_cam_read_index = {fe1_pc[11:4],cam_line_offset_next};

          //   cam_state_next = '{evict:1,default:0};
          // end else begin
          begin
            // initiate bus read
            fe1_cvalid = 1;
            fe1_cmd = 1;
            fe1_addr = {fe1_cam_read_tag_in,fe1_pc[11:2]};

            cam_state_next = '{fill1:1,default:0};
          end
          // end
        else
          fe1_insn = ic_cam_read_data;
      end

      /*
      cam_state.evict: begin
        // continue bus write
        fe1_wvalid = 1;
        fe1_wlast = cam_line_offset_next == fe1_pc[3:2];
        fe1_wdata = ic_cam_read_data;
        fe1_wmask = '1;

        // not last word?
        if(cam_line_offset_next != fe1_pc[3:2]) begin
          // read word from cache
          fe1_cam_read_req = bus_ack;
          fe1_cam_read_index = {fe1_pc[11:4],cam_line_offset_next};
        end else begin
          // mark line invalid
          fe1_cam_write_req_tag_flags = bus_ack;
          fe1_cam_write_flags = 0;

          cam_state_next = '{fill0:1,default:0};
        end
      end

      cam_state.fill0: begin
        // initiate bus read
        fe1_cvalid = 1;
        fe1_cmd = 1;
        fe1_addr = {fe1_cam_read_tag_in,fe1_pc[11:2]};

        cam_state_next = '{fill1:1,default:0};
      end
       */

      cam_state.fill1: begin
        // write word to cache
        fe1_cam_write_index = {fe1_pc[11:4],cam_line_offset};
        fe1_cam_write_req_data = 1;
        fe1_cam_write_data = bmain_rdata;

        // first word?
        if(cam_line_offset_next ^ 'b10 == fe1_pc[3:2]) begin
          // capture instruction
          cam_insn_wen = 1;
          cam_insn_next = bmain_rdata;
        end

        // not last word?
        if(cam_line_offset_next != fe1_pc[3:2])
          // continue bus read
          fe1_rready = 1;
        else begin
          // mark line valid
          fe1_cam_write_req_tag_flags = 1;
          fe1_cam_write_tag = fe1_cam_read_tag_in;
          fe1_cam_write_flags = 'b01;

          // issue instruction
          fe1_insn = cam_insn;

          cam_state_next = '{idle:1,default:0};
        end
       end
    endcase
  end

  assign fe1_stall = fe1_valid & (tlb_stall | cam_stall | de_stall);
  assign fe1_exc = tlb_exc | cam_exc | bmain_error_fe1;

endmodule
