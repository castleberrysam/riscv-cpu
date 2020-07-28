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
  output logic         mem1_mem0_trans,
  output logic [31:2]  mem1_mem0_addr,

  // decode outputs
  output logic         mem1_fwd_valid,
  output logic         mem1_fwd_stall,
  output logic [31:0]  mem1_fwd_data,

  // execute inputs
  input logic          ex_br_miss,

  // dcache inputs
  input logic          dc_tlb_read_hit,
  input logic          dc_tlb_read_super,
  input logic [28:12]  dc_tlb_read_ppn,
  input logic [7:0]    dc_tlb_read_flags,

  input logic          dc_cam_read_hit,
  input logic [31:0]   dc_cam_read_data,
  input logic [28:12]  dc_cam_lru_tag,
  input logic [1:0]    dc_cam_lru_flags,

  // dcache outputs
  output logic         mem1_tlb_write_req,
  output logic         mem1_tlb_write_super,
  output logic [31:21] mem1_tlb_write_tag,
  output logic [8:0]   mem1_tlb_write_asid,
  output logic [28:12] mem1_tlb_write_ppn,
  output logic [7:0]   mem1_tlb_write_flags,

  output logic         mem1_cam_read_req,
  output logic [11:2]  mem1_cam_read_index,
  output logic [28:12] mem1_cam_read_tag,

  output logic         mem1_cam_write_req,
  output logic         mem1_cam_write_lru_way,
  output logic [1:0]   mem1_cam_write_offset,

  output logic [31:0]  mem1_cam_write_data,
  output logic [3:0]   mem1_cam_write_mask,

  output logic [28:12] mem1_cam_write_tag,
  output logic [1:0]   mem1_cam_write_flags,

  output logic         mem1_cam_lru_update,

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

  // write/fetch1 inputs/outputs
  output logic         mem1_valid_wb,
  input logic          wb_stall,
  output logic         mem1_exc,
  output ecause_t      mem1_exc_cause,
  output logic         mem1_flush,
  output logic [31:2]  mem1_pc,

  output logic [4:0]   mem1_wb_reg,
  output logic [31:0]  mem1_dout,

  output logic         mem1_valid_fe1,
  input logic          fe1_mem1_kill
  );

  logic kill;
  assign kill = csr_kill | (mem1_fe1_req & fe1_mem1_kill);

  logic busy, killed;
  always_ff @(posedge clk_core)
    if(~reset_n)
      killed <= 0;
    else if(kill & busy)
      killed <= 1;
    else if(~busy)
      killed <= 0;

  logic        valid;
  logic        mem0_exc_r;
  ecause_t     mem0_exc_cause_r;

  logic        mem1_mem1_req, mem1_fe1_req;

  logic        mem1_write;
  logic        mem1_extend;
  logic [1:0]  mem1_width;
  logic [31:0] mem1_addr, mem1_wdata;
  always_ff @(posedge clk_core)
    if(~reset_n) begin
      valid <= 0;
      mem0_exc_r <= 0;
    end else begin
      mem1_mem1_req <= mem0_mem1_req;
      if(~mem1_stall | ((kill | killed) & ~busy)) begin
        valid <= mem0_valid;
        mem0_exc_r <= mem0_exc;
        mem0_exc_cause_r <= mem0_exc_cause;
        mem1_pc <= mem0_pc;

        mem1_fe1_req <= mem0_fe1_req;

        mem1_read <= mem0_read;
        mem1_write <= mem0_write;
        mem1_extend <= mem0_extend;
        mem1_width <= mem0_width;
        mem1_addr <= mem0_addr;
        mem1_wdata <= mem0_wdata;

        mem1_wb_reg <= mem0_wb_reg;
      end else if(mem1_mem0_read)
        mem1_addr <= mem1_mem0_addr;
    end

  logic mem1_valid;
  assign mem1_valid = valid & ~mem1_stall & ~exc & ~(kill | killed);
  assign mem1_valid_fe1 = mem1_valid & mem1_fe1_req;
  assign mem1_valid_wb = mem1_valid & ~mem1_fe1_req;
  assign mem1_exc = exc & ~(kill | killed);

  assign mem1_fwd_valid = valid & ~mem1_fe1_req;
  assign mem1_fwd_stall = mem1_read & (tlb_stall | cam_stall);
  assign mem1_fwd_data = mem1_dout;

  logic dc_access, csr_access;
  assign dc_access = valid & ((mem1_read ^ mem1_write) | tlb_fill_req);
  assign csr_access = valid & mem1_read & mem1_write & ~tlb_fill_req;

  assign mem1_csr_addr = mem1_addr[11:0];
  assign mem1_csr_write = csr_access ? mem1_width : '0;
  assign mem1_csr_din = mem1_wdata;

  assign mem1_flush = csr_flush;

  logic exc;
  always_comb begin
    exc = mem0_exc_r;
    mem1_exc_cause = mem0_exc_cause_r;
    if(valid) begin
      exc = 1;
      if(tlb_exc | cam_exc | bmain_error_mem1)
        mem1_exc_cause = mem1_write ? SPFAULT : LPFAULT;
      else if(csr_access & csr_error)
        mem1_exc_cause = IILLEGAL;
      else
        exc = 0;
    end
  end

  // tlb state machine
  logic tlb_exc;

  struct packed {
    logic idle, fill0, fill1, fill2, fill3;
  } tlb_state, tlb_state_next;

  always_ff @(posedge clk_core)
    if(~reset_n | tlb_exc | kill | killed)
      tlb_state <= '{idle:1,default:0};
    else
      tlb_state <= tlb_state_next;

  logic tlb_start_fill;
  assign tlb_start_fill = dc_access & virt & (~dc_tlb_read_hit | tlb_set_dirty);

  logic tlb_stall;
  assign tlb_stall = ~tlb_state.idle | tlb_start_fill;

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
  assign pte = pte_t'(cam_dout_raw);

  logic pte_valid, pte_leaf;
  assign pte_valid = pte.flags.v & (pte.flags.r | ~pte.flags.w);
  assign pte_leaf = pte.flags.r | pte.flags.w | pte.flags.x;

  logic tlb_set_dirty;
  assign tlb_set_dirty = mem1_write & ~dc_tlb_read_flags[7];

  logic [31:2] mem1_addr_r;
  always_ff @(posedge clk_core)
    if(tlb_state.idle & tlb_start_fill)
      mem1_addr_r <= mem1_addr;

  assign mem1_tlb_write_ppn = pte.ppn;
  assign mem1_tlb_write_flags = pte.flags;
  assign mem1_tlb_write_tag = mem1_addr_r[31:21];

  always_comb begin
    // set default values of outputs
    tlb_state_next = tlb_state;
    tlb_exc = 0;

    mem1_tlb_write_req = 0;
    mem1_tlb_write_super = 0;

    tlb_cam_read = 0;
    tlb_cam_addr = '0;

    mem1_mem0_read = 0;
    mem1_mem0_trans = 0;
    mem1_mem0_addr = '0;

    unique case(1)
      tlb_state.idle:
        // tlb miss or stale dirty bit?
        if(tlb_start_fill)
          tlb_state_next = '{fill0:1,default:0};

      tlb_state.fill0: begin
        // read first-level PTE
        mem1_mem0_read = 1;
        mem1_mem0_addr = {3'b0,satp_ppn,mem1_addr_r[31:22]};

        tlb_state_next = '{fill1:1,default:0};
      end

      tlb_state.fill1: begin
        mem1_tlb_write_super = 1;

        if(cam_stall)
          // wait for request to complete
          ;
        else if(cam_exc | ~pte_valid)
          // raise exception (access fault/invalid PTE)
          tlb_exc = 1;
        else if(~pte_leaf) begin
          // read second-level PTE
          mem1_mem0_read = 1;
          mem1_mem0_addr = {3'b0,pte.ppn,mem1_addr_r[21:12]};

          tlb_state_next = '{fill2:1,default:0};
        end else if(|pte.ppn[9:0])
          // raise exception (misaligned superpage)
          tlb_exc = 1;
        else begin
          // everything checks out, write superpage to the tlb
          mem1_tlb_write_req = 1;

          tlb_state_next = '{fill3:1,default:0};
        end
      end

      tlb_state.fill2:
        if(cam_stall)
          // wait for request to complete
          ;
        else if(cam_exc | ~pte_valid | ~pte_leaf)
          // raise exception (access fault/invalid PTE)
          tlb_exc = 1;
        else begin
          // everything checks out, write page to the tlb
          mem1_tlb_write_req = 1;

          tlb_state_next = '{fill3:1,default:0};
        end

      tlb_state.fill3: begin
        // redo the initial access
        mem1_mem0_read = 1;
        mem1_mem0_trans = 1;
        mem1_mem0_addr = mem1_addr_r;

        tlb_state_next = '{idle:1,default:0};
      end
    endcase
  end

  // cam state machine
  logic cam_exc;
  assign cam_exc = bmain_error_mem1 | (~cam_state.idle & pma_error);
  assign mem1_eack = bmain_error_mem1;

  logic bus_stall_cmd, bus_stall_wdata, bus_stall_rdata, bus_stall;
  assign bus_stall_cmd = mem1_cvalid & ~bmain_cready_mem1;
  assign bus_stall_wdata = mem1_wvalid & ~bmain_wready_mem1;
  assign bus_stall_rdata = mem1_rready & ~bmain_rvalid_mem1;
  assign bus_stall = bus_stall_cmd | bus_stall_wdata | bus_stall_rdata;

  logic bus_beat_wdata, bus_beat_rdata;
  assign bus_beat_wdata = mem1_wvalid & bmain_wready_mem1;
  assign bus_beat_rdata = mem1_rready & bmain_rvalid_mem1;

  struct packed {
    logic idle, evict0, evict1, fill0, fill1, fill2, uncached;
  } cam_state, cam_state_next;

  logic cam_dout_sel, cam_dout_sel_r;
  always_ff @(posedge clk_core)
    if(~reset_n | cam_exc) begin
      cam_state <= '{idle:1,default:0};
      cam_dout_sel_r <= 0;
    end else if(~bus_stall) begin
      cam_state <= cam_state_next;
      cam_dout_sel_r <= cam_dout_sel;
    end

  logic [3:2] cam_line_offset;
  always_ff @(posedge clk_core)
    if(~reset_n)
      cam_line_offset <= '0;
    else if(bus_beat_rdata | (mem1_cam_read_req & ~bus_stall & ~cam_state.fill2))
      cam_line_offset <= cam_line_offset + 1;

  logic cam_start_fill;
  assign cam_start_fill = dc_access & (~virt | dc_tlb_read_hit) & ~dc_cam_read_hit & ~cam_dout_sel_r;

  logic cam_stall;
  assign cam_stall = bus_stall | ~cam_state.idle | cam_start_fill;

  logic        cam_rword_wen;
  logic [31:0] cam_rword;
  always_ff @(posedge clk_core)
    if(cam_rword_wen)
      cam_rword <= bmain_rdata;

  logic [31:0] cam_wdata;
  logic [3:0]  cam_wmask;
  always_comb begin
    cam_wdata = '0;
    cam_wmask = '0;
    unique0 casez(mem1_width)
      'b00: begin
        cam_wdata[mem1_addr[1:0]*8+:8] = mem1_wdata[7:0];
        cam_wmask[mem1_addr[1:0]] = 1;
      end

      'b01: begin
        cam_wdata[mem1_addr[1]*16+:16] = mem1_wdata[15:0];
        cam_wmask[mem1_addr[1]*2+:2] = '1;
      end

      'b1?: begin
        cam_wdata = mem1_wdata;
        cam_wmask = '1;
      end
    endcase
  end

  logic [31:0] cam_dout, cam_dout_raw;
  always_comb begin
    cam_dout_raw = cam_dout_sel_r ? cam_rword : dc_cam_read_data;

    if(tlb_fill_req) begin
      if(pte_leaf)
        cam_dout = cam_dout_raw | {24'b0,mem1_mem1_req & mem1_write,1'b1,6'b0};
      else
        cam_dout = cam_dout_raw;
    end else
      unique0 casez(mem1_width)
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

  logic [28:12] cam_tag;
  assign cam_tag = virt ? dc_tlb_read_ppn : mem1_addr[28:12];

  assign mem1_wlast = cam_line_offset == 'd0;

  assign mem1_cam_read_index = {mem1_addr[11:4],cam_line_offset};

  always_comb begin
    // set default values of outputs
    cam_state_next = cam_state;

    mem1_cam_read_req = 0;
    mem1_cam_read_tag = '0;

    mem1_cam_write_req = 0;
    mem1_cam_write_lru_way = 0;
    mem1_cam_write_offset = '0;
    mem1_cam_write_data = '0;
    mem1_cam_write_mask = '0;
    mem1_cam_write_tag = '0;
    mem1_cam_write_flags = '0;
    mem1_cam_lru_update = 0;

    cam_rword_wen = 0;
    cam_dout_sel = 0;

    mem1_cvalid = 0;
    mem1_cmd = 0;
    mem1_bus_addr = '0;

    mem1_rready = 0;

    mem1_wvalid = 0;
    mem1_bus_wdata = '0;
    mem1_wmask = '0;

    unique case(1)
      cam_state.idle: begin
        // tlb hit?
        mem1_cam_read_tag = cam_tag;
        mem1_cam_write_lru_way = cam_dout_sel_r;
        mem1_cam_write_offset = mem1_addr[3:2];
        mem1_cam_write_tag = cam_tag;
        mem1_cam_write_flags = 'b11;
        mem1_cam_lru_update = 1;
        if(dc_access & (~virt | dc_tlb_read_hit)) begin
          // cam miss?
          if(~dc_cam_read_hit & ~cam_dout_sel_r) begin
            // need to evict?
            if(dc_cam_lru_flags[0] & dc_cam_lru_flags[1])
              cam_state_next = '{evict0:1,default:0};
            else
              cam_state_next = '{fill0:1,default:0};
          end else if(tlb_fill_req) begin
            mem1_cam_write_data = cam_dout;
            mem1_cam_write_mask = '1;
            if(pte_leaf)
              // update accessed/dirty bits
              mem1_cam_write_req = 1;
          end else begin
            mem1_cam_write_data = cam_wdata;
            mem1_cam_write_mask = cam_wmask;
            if(mem1_write & ~kill)
              // write data to cache
              mem1_cam_write_req = 1;
          end
        end
      end

      cam_state.evict0: begin
        mem1_cvalid = ~pma_error;
        mem1_bus_addr = {dc_cam_lru_tag,mem1_addr[11:4],2'b0};
        if(pma_cacheable) begin
          // initiate bus write
          mem1_cmd = 0;

          // read word from cache
          mem1_cam_read_req = 1;

          cam_state_next = '{evict1:1,default:0};
        end else begin
          // initiate bus access
          mem1_cmd = mem1_read | tlb_fill_req;

          cam_state_next = '{uncached:1,default:0};
        end
      end

      cam_state.evict1: begin
        // continue bus write
        mem1_wvalid = 1;
        mem1_bus_wdata = dc_cam_read_data;
        mem1_wmask = '1;

        // not last word?
        mem1_cam_read_tag = dc_cam_lru_tag;
        if(~mem1_wlast)
          // read word from cache
          mem1_cam_read_req = 1;
        else
          cam_state_next = '{fill0:1,default:0};
      end

      cam_state.fill0: begin
        mem1_cvalid = ~pma_error;
        mem1_bus_addr = {cam_tag,mem1_addr[11:4],2'b0};
        if(pma_cacheable) begin
          // initiate bus read
          mem1_cmd = 1;

          cam_state_next = '{fill1:1,default:0};
        end else begin
          // initiate bus access
          mem1_cmd = mem1_read | tlb_fill_req;

          cam_state_next = '{uncached:1,default:0};
        end
      end

      cam_state.fill1: begin
        // continue bus read
        mem1_rready = 1;

        // write data to cache, mark line valid
        mem1_cam_write_req = 1;
        mem1_cam_write_lru_way = 1;
        mem1_cam_write_offset = cam_line_offset;
        mem1_cam_write_data = bmain_rdata;
        mem1_cam_write_mask = '1;
        mem1_cam_write_tag = cam_tag;
        mem1_cam_write_flags = 'b01;

        // is this the desired word?
        if(cam_line_offset == mem1_addr[3:2])
          // capture read data
          cam_rword_wen = 1;

        // select captured data
        cam_dout_sel = 1;

        // last word?
        if(cam_line_offset == 'd3) begin
          // update lru bits
          mem1_cam_lru_update = 1;

          cam_state_next = '{idle:1,default:0};
        end
      end

      cam_state.uncached: begin
        // continue bus access
        mem1_rready = mem1_read | tlb_fill_req;
        mem1_wvalid = mem1_write & ~tlb_fill_req;
        mem1_bus_wdata = cam_wdata;
        mem1_wmask = cam_wmask;

        // capture read data
        cam_rword_wen = 1;

        // select captured data
        cam_dout_sel = 1;

        cam_state_next = '{idle:1,default:0};
      end
    endcase
  end

  logic pma_error, pma_cacheable;
  pma_checker pma_checker(
    .clk_core(clk_core),
    .reset_n(reset_n),

    .read(mem1_read),
    .write(mem1_write),
    .width(mem1_width),
    .ppn(cam_tag),

    .pma_cacheable(pma_cacheable),
    .pma_error(pma_error)
    );

  always_comb
    unique case(1)
      dc_access: mem1_dout = cam_dout;
      csr_access: mem1_dout = csr_dout;
      default: mem1_dout = mem1_addr;
    endcase

  assign busy = cam_stall;
  assign mem1_stall = (valid & (tlb_stall | cam_stall | (~mem1_fe1_req & wb_stall))) | (exc & ~mem1_fe1_req & wb_stall);

endmodule
