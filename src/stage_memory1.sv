`timescale 1ns/1ps

`include "defines.svh"

module stage_memory1(
  input logic          clk_core,
  input logic          reset_n,

  // memory0 inputs/outputs
  input logic          mem0_valid,
  input logic          mem0_stall,
  output logic         mem1_stall,
  input logic          mem0_exc,
  input ecause_t       mem0_exc_cause,
  input logic [31:2]   mem0_pc,

  input logic          mem0_mem1_req,
  input logic          mem0_fe1_req,

  input logic          mem0_read,
  input logic          mem0_write,
  input logic          mem0_extend,
  input logic [1:0]    mem0_width,
  input logic [31:0]   mem0_addr,
  input logic [31:0]   mem0_wdata,

  input logic [4:0]    mem0_wb_reg,

  output logic         mem1_mem0_read,
  output logic [28:2]  mem1_mem0_addr,

  // decode outputs
  output logic [31:0]  mem1_fwd_data,

  // dcache inputs
  input logic          dc_tlb_read_hit,
  input logic          dc_tlb_read_super,
  input logic [28:12]  dc_tlb_read_ppn,
  input logic [7:0]    dc_tlb_read_flags,

  input logic          dc_cam_read_hit,
  input logic [28:12]  dc_cam_read_tag_out,
  input logic [31:0]   dc_cam_read_data,
  input logic [1:0]    dc_cam_read_flags, 

  // dcache outputs
  output logic         mem1_tlb_write_req,
  output logic         mem1_tlb_write_super,
  output logic [31:21] mem1_tlb_write_tag,
  output logic [8:0]   mem1_tlb_write_asid,
  output logic [28:12] mem1_tlb_write_ppn,
  output logic [7:0]   mem1_tlb_write_flags,

  output logic [28:12] mem1_cam_read_tag_in,

  output logic         mem1_cam_read_req,
  output logic [11:2]  mem1_cam_read_index,

  output logic [11:2]  mem1_cam_write_index,

  output logic         mem1_cam_write_req_data,
  output logic [31:0]  mem1_cam_write_data,
  output logic [3:0]   mem1_cam_write_mask,

  output logic         mem1_cam_write_req_tag_flags,
  output logic [28:12] mem1_cam_write_tag,
  output logic [1:0]   mem1_cam_write_flags,

  // bus inputs/outputs
  output logic         mem1_cvalid,
  input logic          bmain_cready_mem1,
  output logic         mem1_cmd,
  output logic [28:2]  mem1_bus_addr,

  output logic         mem1_wvalid,
  input logic          bmain_wready_mem1,
  output logic         mem1_wlast,
  output logic [31:0]  mem1_bus_wdata,
  output logic [3:0]   mem1_wmask,

  input logic          bmain_rvalid_mem1,
  output logic         mem1_rready,
  input logic          bmain_rlast,
  input [31:0]         bmain_rdata,

  input logic          bmain_error_mem1,
  output logic         mem1_eack,

  // csr inputs/outputs
  output logic [11:0]  mem1_csr_addr,
  output logic [1:0]   mem1_csr_write,
  output logic [31:0]  mem1_csr_din,

  input logic          csr_error,
  input logic          csr_flush,
  input logic [31:0]   csr_dout,

  input logic          csr_kill,

  input logic [31:0]   csr_satp,

  // forward outputs
  output logic         mem1_read,

  // write inputs/outputs
  output logic         mem1_valid_fe1,
  output logic         mem1_valid_wb,
  input logic          wb_stall,
  output logic         mem1_exc,
  output ecause_t      mem1_exc_cause,
  output logic         mem1_flush,
  output logic [31:2]  mem1_pc,

  output logic         mem1_busy,

  output logic [4:0]   mem1_wb_reg,
  output logic [31:0]  mem1_dout
  );

  logic        mem1_valid;
  logic        mem0_exc_r;
  ecause_t     mem0_exc_cause_r;

  logic        mem1_mem1_req, mem1_fe1_req;

  logic        mem1_write;
  logic        mem1_extend;
  logic [1:0]  mem1_width;
  logic [31:0] mem1_addr, mem1_wdata;
  always_ff @(posedge clk_core)
    if(~reset_n) begin
      mem1_valid <= 0;
      mem0_exc_r <= 0;
    end else begin
      mem1_mem1_req <= mem0_mem1_req;
      mem1_fe1_req <= mem0_fe1_req;
      if(~mem1_stall | csr_kill) begin
        mem1_valid <= mem0_valid & ~mem0_stall & ~mem0_exc & ~csr_kill;
        mem0_exc_r <= mem0_exc & ~csr_kill;
        mem0_exc_cause_r <= mem0_exc_cause;
        mem1_pc <= mem0_pc;

        mem1_read <= mem0_read;
        mem1_write <= mem0_write;
        mem1_extend <= mem0_extend;
        mem1_width <= mem0_width;
        mem1_addr <= mem0_addr;
        mem1_wdata <= mem0_wdata;

        mem1_wb_reg <= mem0_wb_reg;
      end
    end

  assign mem1_valid_fe1 = mem1_valid & mem1_fe1_req;
  assign mem1_valid_wb = mem1_valid & ~mem1_fe1_req;

  assign mem1_fwd_data = mem1_addr;

  logic dc_access, csr_access;
  assign dc_access = mem1_valid & (mem1_read ^ mem1_write);
  assign csr_access = mem1_valid & mem1_read & mem1_write;

  assign mem1_csr_addr = mem1_addr[11:0];
  assign mem1_csr_write = csr_access ? mem1_width : '0;
  assign mem1_csr_din = mem1_wdata;

  assign mem1_flush = csr_flush;

  always_comb begin
    mem1_exc = mem0_exc_r;
    mem1_exc_cause = mem0_exc_cause_r;
    if(mem1_valid) begin
      mem1_exc = 1;
      if(tlb_exc | cam_exc | bmain_error_mem1)
        mem1_exc_cause = mem1_write ? SPFAULT : LPFAULT;
      else if(csr_access & csr_error)
        mem1_exc_cause = IILLEGAL;
      else
        mem1_exc = 0;
    end
  end

  // tlb state machine
  struct packed {
    logic idle, fill0, fill1;
  } tlb_state, tlb_state_next;

  always_ff @(posedge clk_core)
    if(~reset_n)
      tlb_state <= '{idle:1,default:0};
    else if(csr_kill)
      tlb_state <= '{idle:1,default:0};
    else
      tlb_state <= tlb_state_next;

  logic tlb_stall;
  assign tlb_stall = ~tlb_state_next.idle;

  logic         satp_mode;
  logic [8:0]   satp_asid;
  logic [28:12] satp_ppn;
  assign satp_mode = csr_satp[31];
  assign satp_asid = csr_satp[30:22];
  assign satp_ppn  = csr_satp[16:0];

  assign mem1_tlb_write_asid = satp_asid;

  logic        tlb_cam_read;
  logic [28:2] tlb_cam_addr;

  logic tlb_fill_req;
  assign tlb_fill_req = mem1_mem1_req | mem1_fe1_req;

  logic virt;
  assign virt = satp_mode & ~tlb_fill_req;

  pte_t pte;
  assign pte = pte_t'(dc_cam_read_data);

  logic pte_valid, pte_leaf;
  assign pte_valid = pte.flags.v & (pte.flags.r | ~pte.flags.w);
  assign pte_leaf = pte.flags.r | pte.flags.w | pte.flags.x;

  logic tlb_set_dirty;
  assign tlb_set_dirty = mem1_write & ~dc_tlb_read_flags[7];

  logic tlb_exc;
  always_comb begin
    // set default values of outputs
    tlb_state_next = tlb_state;
    tlb_exc = 0;

    mem1_tlb_write_req = 0;
    mem1_tlb_write_super = 0;
    mem1_tlb_write_tag = 0;
    mem1_tlb_write_ppn = 0;
    mem1_tlb_write_flags = 0;

    tlb_cam_read = 0;
    tlb_cam_addr = '0;

    mem1_mem0_read = 0;
    mem1_mem0_addr = '0;

    unique case(1)
      tlb_state.idle:
        if(dc_access & virt)
          // tlb miss or stale dirty bit?
          if(~dc_tlb_read_hit | tlb_set_dirty) begin
            // read first-level PTE
            mem1_mem0_read = 1;
            mem1_mem0_addr = {satp_ppn,mem1_addr[31:22]};
            tlb_state_next = '{fill0:1,default:0};
          end

      tlb_state.fill0:
        if(cam_stall)
          // wait for request to complete
          mem1_mem0_addr = {satp_ppn,mem1_addr[31:22]};          
        else if(cam_exc | ~pte_valid) begin
          // raise exception (access fault/invalid PTE)
          tlb_exc = 1;
          tlb_state_next = '{idle:1,default:0};
        end else if(~pte_leaf) begin
          // read second-level PTE
          mem1_mem0_read = 1;
          mem1_mem0_addr = {pte.ppn,mem1_addr[21:12]};
          tlb_state_next = '{fill1:1,default:0};
        end else if(|pte.ppn[9:0]) begin
          // raise exception (misaligned superpage)
          tlb_exc = 1;
          tlb_state_next = '{idle:1,default:0};
        end else begin
          // everything checks out, write superpage to the tlb
          mem1_tlb_write_req = 1;
          mem1_tlb_write_super = 1;
          mem1_tlb_write_ppn = pte.ppn;
          mem1_tlb_write_flags = pte.flags;

          tlb_state_next = '{idle:1,default:0};
        end

      tlb_state.fill1:
        if(cam_stall)
          // wait for request to complete
          mem1_mem0_addr = {pte.ppn,mem1_addr[21:12]};
        else if(cam_exc | ~pte_valid | pte_leaf) begin
          // raise exception (access fault/invalid PTE)
          tlb_exc = 1;
          tlb_state_next = '{idle:1,default:0};
        end else begin
          // everything checks out, write page to the tlb
          mem1_tlb_write_req = 1;
          mem1_tlb_write_tag = mem1_addr[31:21];
          mem1_tlb_write_ppn = pte.ppn;
          mem1_tlb_write_flags = pte.flags;

          tlb_state_next = '{idle:1,default:0};
        end
    endcase
  end

  // cam state machine
  assign mem1_eack = bmain_error_mem1;

  logic bus_stall_cmd, bus_stall_wdata, bus_stall_rdata, bus_stall;
  assign bus_stall_cmd = mem1_cvalid & ~bmain_cready_mem1;
  assign bus_stall_wdata = mem1_wvalid & ~bmain_wready_mem1;
  assign bus_stall_rdata = mem1_rready & ~bmain_rvalid_mem1;
  assign bus_stall = bus_stall_cmd | bus_stall_wdata | bus_stall_rdata;

  struct packed {
    logic idle, evict, fill0, fill1;
  } cam_state, cam_state_next;

  always_ff @(posedge clk_core)
    if(~reset_n)
      cam_state <= '{idle:1,default:0};
    else if(bmain_error_mem1)
      cam_state <= '{idle:1,default:0};
    else if(~bus_stall)
      cam_state <= cam_state_next;

  logic cam_stall;
  assign cam_stall = bus_stall | ~cam_state_next.idle;

  // tlb write passthrough
  logic         cam_tlb_hit;
  logic [28:12] cam_tlb_ppn;
  logic [7:0]   cam_tlb_flags;
  always_comb begin
    cam_tlb_hit = dc_tlb_read_hit | mem1_tlb_write_req;
    if(mem1_tlb_write_req) begin
      cam_tlb_ppn = mem1_tlb_write_ppn;
      cam_tlb_flags = mem1_tlb_write_flags;
    end else begin
      cam_tlb_ppn = dc_tlb_read_ppn;
      cam_tlb_flags = dc_tlb_read_flags;
    end
  end

  assign mem1_cam_read_tag_in = virt ? cam_tlb_ppn : mem1_addr[28:12];

  logic [3:2] cam_line_offset, cam_line_offset_next;
  always_comb
    unique case(1)
      cam_state_next.evict: cam_line_offset_next = mem1_addr[3:2] + 1;
      cam_state_next.fill1: cam_line_offset_next = mem1_addr[3:2];
      default: cam_line_offset_next = cam_line_offset + 1;
    endcase
  always_ff @(posedge clk_core)
    if(~bus_stall_rdata & ~bus_stall_wdata)
      cam_line_offset <= cam_line_offset_next;

  logic        cam_rword_wen;
  logic [31:0] cam_rword, cam_rword_next;
  always_ff @(posedge clk_core)
    if(cam_rword_wen)
      cam_rword <= cam_rword_next;

  logic [31:0] cam_wdata, cam_wmask;
  always_comb begin
    cam_wdata = '0;
    cam_wmask = '0;
    unique casez(mem1_width)
      'b00: begin
        cam_wdata[mem1_addr[1:0]*8+:8] = mem1_wdata[7:0];
        cam_wmask[mem1_addr[1:0]*8+:8] = '1;
      end

      'b01: begin
        cam_wdata[mem1_addr[1]*16+:16] = mem1_wdata[15:0];
        cam_wmask[mem1_addr[1]*16+:16] = '1;
      end

      'b1?: begin
        cam_wdata = mem1_wdata;
        cam_wmask = '1;
      end
    endcase
  end

  logic        cam_dout_sel;
  logic [31:0] cam_dout, cam_dout_raw;
  always_comb begin
    cam_dout_raw = cam_dout_sel ? cam_rword : dc_cam_read_data;

    unique casez(mem1_width)
      'b00: begin
        cam_dout[7:0] = cam_dout_raw[mem1_addr[1:0]*8+:8];
        cam_dout[31:8] = mem1_extend ? cam_dout[7] : '0;
      end

      'b01: begin
        cam_dout[15:0] = cam_dout_raw[mem1_addr[1]*16+:16];
        cam_dout[31:16] = mem1_extend ? cam_dout[15] : '0;
      end

      'b1?:
        cam_dout = cam_dout_raw;
    endcase
  end

  logic        cam_exc;
  always_comb begin
    // set default values of outputs
    cam_state_next = cam_state;
    cam_exc = 0;

    mem1_cam_read_req = 0;
    mem1_cam_read_index = '0;

    mem1_cam_write_index = '0;

    mem1_cam_write_req_data = 0;
    mem1_cam_write_data = '0;
    mem1_cam_write_mask = '0;

    mem1_cam_write_req_tag_flags = 0;
    mem1_cam_write_tag = '0;
    mem1_cam_write_flags = '0;

    cam_dout_sel = 0;

    cam_rword_wen = 0;
    cam_rword_next = '0;

    mem1_cvalid = 0;
    mem1_cmd = 0;
    mem1_bus_addr = '0;

    mem1_wvalid = 0;
    mem1_wlast = 0;
    mem1_bus_wdata = '0;
    mem1_wmask = '0;

    mem1_rready = 0;

    unique case(1)
      cam_state.idle: begin
        // tlb hit?
        if(dc_access & ~csr_kill & (~virt | dc_tlb_read_hit))
          // cam miss?
          if(~dc_cam_read_hit) begin
            // need to evict?
            if(dc_cam_read_flags[0] & dc_cam_read_flags[1]) begin
              // initiate bus write
              mem1_cvalid = 1;
              mem1_cmd = 0;
              mem1_bus_addr = {dc_cam_read_tag_out,mem1_addr[11:2]};

              mem1_wvalid = 1;
              mem1_wlast = 0;
              mem1_bus_wdata = dc_cam_read_data;
              mem1_wmask = '1;

              // read word from cache
              mem1_cam_read_req = ~bus_stall_wdata;
              mem1_cam_read_index = {mem1_addr[11:4],cam_line_offset_next};

              cam_state_next = '{evict:1,default:0};
            end else begin
              // initiate bus read
              mem1_cvalid = 1;
              mem1_cmd = 1;
              mem1_bus_addr = {mem1_cam_read_tag_in,mem1_addr[11:2]};

              cam_state_next = '{fill1:1,default:0};
            end
          end else if(tlb_fill_req & pte_leaf) begin
            // update accessed/dirty bits
            mem1_cam_write_index = mem1_mem0_addr[11:2];
            mem1_cam_write_req_data = 1;
            mem1_cam_write_data = dc_cam_read_data | {mem1_write,1'b1,6'b0};
            mem1_cam_write_mask = '1;
          end else if(mem1_write) begin
            // write data to cache
            mem1_cam_write_index = mem1_addr[11:2];
            mem1_cam_write_req_data = 1;
            mem1_cam_write_data = cam_wdata;
            mem1_cam_write_mask = cam_wmask;
          end
      end

      cam_state.evict: begin
        // continue bus write
        mem1_wvalid = 1;
        mem1_wlast = cam_line_offset_next == mem1_addr[3:2];
        mem1_bus_wdata = dc_cam_read_data;
        mem1_wmask = '1;

        // not last word?
        if(cam_line_offset_next != mem1_addr[3:2]) begin
          // read word from cache
          mem1_cam_read_req = ~bus_stall_wdata;
          mem1_cam_read_index = {mem1_addr[11:4],cam_line_offset_next};
        end else begin
          // mark line invalid
          mem1_cam_write_req_tag_flags = ~bus_stall_wdata;
          mem1_cam_write_flags = 0;

          cam_state_next = '{fill0:1,default:0};
        end
      end

      cam_state.fill0: begin
        // initiate bus read
        mem1_cvalid = 1;
        mem1_cmd = 1;
        mem1_bus_addr = {mem1_cam_read_tag_in,mem1_addr[11:2]};

        cam_state_next = '{fill1:1,default:0};
      end

      cam_state.fill1: begin
        // write word to cache
        mem1_cam_write_index = {mem1_addr[11:4],cam_line_offset};
        mem1_cam_write_req_data = 1;
        mem1_cam_write_data = bmain_rdata;
        mem1_cam_write_mask = '1;

        // first word?
        if(cam_line_offset_next ^ 'b10 == mem1_addr[3:2]) begin
          // capture read data
          cam_rword_wen = 1;
          cam_rword_next = bmain_rdata;
        end

        // not last word?
        if(cam_line_offset_next != mem1_addr[3:2])
          // continue bus read
          mem1_rready = 1;
        else begin
          // mark line valid
          mem1_cam_write_req_tag_flags = 1;
          mem1_cam_write_tag = mem1_cam_read_tag_in;
          mem1_cam_write_flags = 'b01;

          // issue read data
          cam_dout_sel = 1;

          cam_state_next = '{idle:1,default:0};
        end
       end
    endcase
  end

  assign mem1_dout = csr_access ? csr_dout : cam_dout;

  assign mem1_busy = mem1_valid & cam_stall;
  assign mem1_stall = (mem1_valid & (tlb_stall | cam_stall | wb_stall)) | (mem1_exc & wb_stall);

endmodule
