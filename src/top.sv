`timescale 1ns/1ps

`include "defines.svh"

module top(
  input logic         clk_core,
  input logic         clk_mig_sys,
  input logic         clk_mig_ref,
  input logic         reset_n,

  output logic [13:0] ddr3_addr,
  output logic [2:0]  ddr3_ba,
  output logic        ddr3_ras_n,
  output logic        ddr3_cas_n,
  output logic        ddr3_we_n,
  output logic        ddr3_reset_n,
  output logic        ddr3_ck_p,
  output logic        ddr3_ck_n,
  output logic        ddr3_cke,
  output logic        ddr3_cs_n,
  output logic [1:0]  ddr3_dm,
  output logic        ddr3_odt,
  inout logic [15:0]  ddr3_dq,
  inout logic [1:0]   ddr3_dqs_p,
  inout logic [1:0]   ddr3_dqs_n
  );

  logic        mig_ui_clk;
  logic        mig_ui_reset;
  logic        mig_rvalid;
  logic        mig_rlast;
  logic [63:0] mig_rdata;
  logic        mig_cready;
  logic        mig_wready;

  /*AUTOWIRE*/
  // Beginning of automatic wires (for undeclared instantiated-module outputs)
  logic [27:2]          bmain_addr;
  logic                 bmain_cmd;
  logic                 bmain_cready_fe1;
  logic                 bmain_cready_mem1;
  logic                 bmain_cvalid_bmmio;
  logic                 bmain_cvalid_dctl;
  logic                 bmain_cvalid_flash;
  logic                 bmain_cvalid_rom;
  logic                 bmain_eack_bmmio;
  logic                 bmain_eack_dctl;
  logic                 bmain_eack_flash;
  logic                 bmain_eack_rom;
  logic                 bmain_error_fe1;
  logic                 bmain_error_mem1;
  logic [31:0]          bmain_rdata;
  logic                 bmain_rlast;
  logic                 bmain_rready_bmmio;
  logic                 bmain_rready_dctl;
  logic                 bmain_rready_flash;
  logic                 bmain_rready_rom;
  logic                 bmain_rvalid_fe1;
  logic                 bmain_rvalid_mem1;
  logic [31:0]          bmain_wdata;
  logic                 bmain_wlast;
  logic [3:0]           bmain_wmask;
  logic                 bmain_wready_mem1;
  logic                 bmain_wvalid_bmmio;
  logic                 bmain_wvalid_dctl;
  logic                 bmain_wvalid_flash;
  logic [7:2]           bmmio_addr;
  logic                 bmmio_cmd;
  logic                 bmmio_cready;
  logic                 bmmio_cvalid_lcd;
  logic                 bmmio_cvalid_spi;
  logic                 bmmio_eack_lcd;
  logic                 bmmio_eack_spi;
  logic                 bmmio_error;
  logic [31:0]          bmmio_rdata;
  logic                 bmmio_rready_lcd;
  logic                 bmmio_rready_spi;
  logic                 bmmio_rvalid;
  logic [31:0]          bmmio_wdata;
  logic                 bmmio_wready;
  logic                 bmmio_wvalid_lcd;
  logic                 bmmio_wvalid_spi;
  logic [31:0]          csr_dout;
  logic                 csr_error;
  logic                 csr_fe_inhibit;
  logic                 csr_flush;
  logic                 csr_kill;
  logic [31:2]          csr_newpc;
  logic [31:0]          csr_satp;
  logic                 csr_setpc;
  logic [31:0]          dc_cam_read_data;
  logic [1:0]           dc_cam_read_flags;
  logic                 dc_cam_read_hit;
  logic [28:12]         dc_cam_read_tag_out;
  logic [7:0]           dc_tlb_read_flags;
  logic                 dc_tlb_read_hit;
  logic [28:12]         dc_tlb_read_ppn;
  logic                 dc_tlb_read_super;
  logic [27:0]          dctl_addr;
  logic [2:0]           dctl_cmd;
  logic                 dctl_cready;
  logic                 dctl_cvalid;
  logic                 dctl_error;
  logic [31:0]          dctl_rdata;
  logic                 dctl_rlast;
  logic                 dctl_rvalid;
  logic [63:0]          dctl_wdata;
  logic                 dctl_wlast;
  logic [7:0]           dctl_wmask;
  logic                 dctl_wready;
  logic                 dctl_wvalid;
  logic                 de_br;
  logic                 de_br_inv;
  logic                 de_br_misalign;
  logic                 de_br_miss_misalign;
  logic                 de_br_pred;
  logic                 de_data1_sel;
  logic                 de_exc;
  ecause_t              de_exc_cause;
  logic [31:0]          de_imm;
  logic                 de_jump;
  logic                 de_mem_extend;
  logic                 de_mem_read;
  logic [1:0]           de_mem_width;
  logic                 de_mem_write;
  logic [31:2]          de_newpc;
  aluop_t               de_op;
  logic [31:2]          de_pc;
  logic [31:0]          de_rdata1;
  logic [31:0]          de_rdata2;
  logic [4:0]           de_rs1;
  logic [4:0]           de_rs2;
  logic                 de_setpc;
  logic                 de_setspecid;
  logic                 de_specid;
  logic                 de_stall;
  logic                 de_sub_sra;
  logic                 de_use_imm;
  logic                 de_use_pc;
  logic                 de_valid;
  logic [4:0]           de_wb_reg;
  logic                 ex_br_miss;
  logic                 ex_br_ntaken;
  logic                 ex_br_taken;
  logic [31:0]          ex_data0;
  logic [31:0]          ex_data1;
  logic                 ex_exc;
  ecause_t              ex_exc_cause;
  logic [31:0]          ex_fwd_data;
  logic                 ex_fwd_stall;
  logic                 ex_fwd_valid;
  logic                 ex_mem_extend;
  logic                 ex_mem_read;
  logic [1:0]           ex_mem_width;
  logic                 ex_mem_write;
  logic [31:2]          ex_pc;
  logic                 ex_specid;
  logic                 ex_stall;
  logic                 ex_valid;
  logic [4:0]           ex_wb_reg;
  logic [31:2]          fe0_read_addr;
  logic [8:0]           fe0_read_asid;
  logic                 fe0_read_req;
  logic                 fe0_specid;
  logic                 fe0_valid;
  logic [28:2]          fe1_addr;
  logic [28:12]         fe1_cam_read_tag_in;
  logic [31:0]          fe1_cam_write_data;
  logic [1:0]           fe1_cam_write_flags;
  logic [11:2]          fe1_cam_write_index;
  logic                 fe1_cam_write_req_data;
  logic                 fe1_cam_write_req_tag_flags;
  logic [28:12]         fe1_cam_write_tag;
  logic                 fe1_cmd;
  logic                 fe1_cvalid;
  logic                 fe1_eack;
  logic                 fe1_exc;
  logic [31:0]          fe1_insn;
  logic [28:2]          fe1_mem0_addr;
  logic                 fe1_mem0_read;
  logic                 fe1_mem1_kill;
  logic [31:2]          fe1_pc;
  logic                 fe1_rready;
  logic                 fe1_specid;
  logic                 fe1_stall;
  logic [31:12]         fe1_tlb_read_addr;
  logic [8:0]           fe1_tlb_read_asid;
  logic                 fe1_tlb_read_req;
  logic [8:0]           fe1_tlb_write_asid;
  logic [7:0]           fe1_tlb_write_flags;
  logic [28:12]         fe1_tlb_write_ppn;
  logic                 fe1_tlb_write_req;
  logic                 fe1_tlb_write_super;
  logic [31:21]         fe1_tlb_write_tag;
  logic                 fe1_valid;
  fwd_type_t            fwd_rs1;
  fwd_type_t            fwd_rs2;
  logic                 fwd_stall;
  logic [31:0]          ic_cam_read_data;
  logic [1:0]           ic_cam_read_flags;
  logic                 ic_cam_read_hit;
  logic [28:12]         ic_cam_read_tag_out;
  logic [7:0]           ic_tlb_read_flags;
  logic                 ic_tlb_read_hit;
  logic [28:12]         ic_tlb_read_ppn;
  logic                 ic_tlb_read_super;
  logic [31:0]          mem0_addr;
  logic [31:2]          mem0_dc_addr;
  logic [8:0]           mem0_dc_asid;
  logic                 mem0_dc_read;
  logic                 mem0_dc_trans;
  logic                 mem0_exc;
  ecause_t              mem0_exc_cause;
  logic                 mem0_extend;
  logic                 mem0_fe1_req;
  logic [31:0]          mem0_fwd_data;
  logic                 mem0_fwd_stall;
  logic                 mem0_fwd_valid;
  logic                 mem0_mem1_req;
  logic [31:2]          mem0_pc;
  logic                 mem0_read;
  logic                 mem0_stall;
  logic                 mem0_valid;
  logic [4:0]           mem0_wb_reg;
  logic [31:0]          mem0_wdata;
  logic [1:0]           mem0_width;
  logic                 mem0_write;
  logic [28:2]          mem1_bus_addr;
  logic [31:0]          mem1_bus_wdata;
  logic [11:2]          mem1_cam_read_index;
  logic                 mem1_cam_read_req;
  logic [28:12]         mem1_cam_read_tag_in;
  logic [31:0]          mem1_cam_write_data;
  logic [1:0]           mem1_cam_write_flags;
  logic [11:2]          mem1_cam_write_index;
  logic [3:0]           mem1_cam_write_mask;
  logic                 mem1_cam_write_req_data;
  logic                 mem1_cam_write_req_tag_flags;
  logic [28:12]         mem1_cam_write_tag;
  logic                 mem1_cmd;
  logic [11:0]          mem1_csr_addr;
  logic [31:0]          mem1_csr_din;
  logic [1:0]           mem1_csr_write;
  logic                 mem1_cvalid;
  logic [31:0]          mem1_dout;
  logic                 mem1_eack;
  logic                 mem1_exc;
  ecause_t              mem1_exc_cause;
  logic                 mem1_flush;
  logic [31:0]          mem1_fwd_data;
  logic                 mem1_fwd_stall;
  logic                 mem1_fwd_valid;
  logic [31:2]          mem1_mem0_addr;
  logic                 mem1_mem0_read;
  logic                 mem1_mem0_trans;
  logic [31:2]          mem1_pc;
  logic                 mem1_read;
  logic                 mem1_rready;
  logic                 mem1_stall;
  logic [8:0]           mem1_tlb_write_asid;
  logic [7:0]           mem1_tlb_write_flags;
  logic [28:12]         mem1_tlb_write_ppn;
  logic                 mem1_tlb_write_req;
  logic                 mem1_tlb_write_super;
  logic [31:21]         mem1_tlb_write_tag;
  logic                 mem1_valid_fe1;
  logic                 mem1_valid_wb;
  logic [4:0]           mem1_wb_reg;
  logic                 mem1_wlast;
  logic [3:0]           mem1_wmask;
  logic                 mem1_wvalid;
  logic                 rom_cready;
  logic                 rom_error;
  logic [31:0]          rom_rdata;
  logic                 rom_rlast;
  logic                 rom_rvalid;
  logic [31:0]          wb_data;
  logic                 wb_exc;
  ecause_t              wb_exc_cause;
  logic                 wb_flush;
  logic [31:2]          wb_pc;
  logic [4:0]           wb_reg;
  logic                 wb_stall;
  logic                 wb_valid;
  // End of automatics

  logic        flash_cready;
  logic        flash_wready;
  logic        flash_rvalid;
  logic        flash_rlast;
  logic [31:0] flash_rdata;
  logic        flash_error;
  assign flash_cready = 0;
  assign flash_wready = 0;
  assign flash_rvalid = 0;
  assign flash_rlast = 0;
  assign flash_rdata = '0;
  assign flash_error = 0;

  logic        lcd_cready;
  logic        lcd_wready;
  logic        lcd_rvalid;
  logic [31:0] lcd_rdata;
  logic        lcd_error;
  assign lcd_cready = 0;
  assign lcd_wready = 0;
  assign lcd_rvalid = 0;
  assign lcd_rdata = '0;
  assign lcd_error = 0;

  logic        spi_cready;
  logic        spi_wready;
  logic        spi_rvalid;
  logic [31:0] spi_rdata;
  logic        spi_error;
  assign spi_cready = 0;
  assign spi_wready = 0;
  assign spi_rvalid = 0;
  assign spi_rdata = '0;
  assign spi_error = 0;

  stage_fetch0 fetch0
    (/*AUTOINST*/
     // Outputs
     .fe0_valid,
     .fe0_specid,
     .fe0_read_req,
     .fe0_read_asid     (fe0_read_asid[8:0]),
     .fe0_read_addr     (fe0_read_addr[31:2]),
     // Inputs
     .clk_core,
     .reset_n,
     .fe1_stall,
     .de_setpc,
     .de_setspecid,
     .de_newpc          (de_newpc[31:2]),
     .csr_fe_inhibit,
     .csr_setpc,
     .csr_newpc         (csr_newpc[31:2]),
     .csr_satp          (csr_satp[31:0]));

  stage_fetch1 fetch1
    (/*AUTOINST*/
     // Outputs
     .fe1_stall,
     .fe1_tlb_read_req,
     .fe1_tlb_read_asid (fe1_tlb_read_asid[8:0]),
     .fe1_tlb_read_addr (fe1_tlb_read_addr[31:12]),
     .fe1_tlb_write_req,
     .fe1_tlb_write_super,
     .fe1_tlb_write_tag (fe1_tlb_write_tag[31:21]),
     .fe1_tlb_write_asid(fe1_tlb_write_asid[8:0]),
     .fe1_tlb_write_ppn (fe1_tlb_write_ppn[28:12]),
     .fe1_tlb_write_flags(fe1_tlb_write_flags[7:0]),
     .fe1_cam_read_tag_in(fe1_cam_read_tag_in[28:12]),
     .fe1_cam_write_index(fe1_cam_write_index[11:2]),
     .fe1_cam_write_req_data,
     .fe1_cam_write_data(fe1_cam_write_data[31:0]),
     .fe1_cam_write_req_tag_flags,
     .fe1_cam_write_tag (fe1_cam_write_tag[28:12]),
     .fe1_cam_write_flags(fe1_cam_write_flags[1:0]),
     .fe1_valid,
     .fe1_exc,
     .fe1_pc            (fe1_pc[31:2]),
     .fe1_specid,
     .fe1_insn          (fe1_insn[31:0]),
     .fe1_mem0_read,
     .fe1_mem0_addr     (fe1_mem0_addr[28:2]),
     .fe1_mem1_kill,
     .fe1_cvalid,
     .fe1_cmd,
     .fe1_addr          (fe1_addr[28:2]),
     .fe1_rready,
     .fe1_eack,
     // Inputs
     .clk_core,
     .reset_n,
     .fe0_valid,
     .fe0_specid,
     .fe0_read_addr     (fe0_read_addr[31:2]),
     .ic_tlb_read_hit,
     .ic_tlb_read_super,
     .ic_tlb_read_ppn   (ic_tlb_read_ppn[28:12]),
     .ic_tlb_read_flags (ic_tlb_read_flags[7:0]),
     .ic_cam_read_hit,
     .ic_cam_read_tag_out(ic_cam_read_tag_out[28:12]),
     .ic_cam_read_data  (ic_cam_read_data[31:0]),
     .ic_cam_read_flags (ic_cam_read_flags[1:0]),
     .de_stall,
     .ex_valid,
     .ex_specid,
     .ex_br_taken,
     .ex_br_ntaken,
     .mem0_valid,
     .mem1_valid_fe1,
     .mem1_stall,
     .mem1_exc,
     .mem1_exc_cause,
     .mem1_dout         (mem1_dout[31:0]),
     .csr_kill,
     .csr_satp          (csr_satp[31:0]),
     .bmain_cready_fe1,
     .bmain_rvalid_fe1,
     .bmain_rlast,
     .bmain_rdata       (bmain_rdata[31:0]),
     .bmain_error_fe1);

  stage_decode decode
    (/*AUTOINST*/
     // Outputs
     .de_setpc,
     .de_setspecid,
     .de_newpc          (de_newpc[31:2]),
     .de_stall,
     .de_valid,
     .de_exc,
     .de_exc_cause,
     .de_pc             (de_pc[31:2]),
     .de_specid,
     .de_rdata1         (de_rdata1[31:0]),
     .de_rdata2         (de_rdata2[31:0]),
     .de_imm            (de_imm[31:0]),
     .de_use_pc,
     .de_use_imm,
     .de_sub_sra,
     .de_data1_sel,
     .de_op,
     .de_br,
     .de_br_inv,
     .de_br_pred,
     .de_jump,
     .de_br_misalign,
     .de_br_miss_misalign,
     .de_mem_read,
     .de_mem_write,
     .de_mem_extend,
     .de_mem_width      (de_mem_width[1:0]),
     .de_wb_reg         (de_wb_reg[4:0]),
     .de_rs1            (de_rs1[4:0]),
     .de_rs2            (de_rs2[4:0]),
     // Inputs
     .clk_core,
     .reset_n,
     .fe1_valid,
     .fe1_stall,
     .fe1_exc,
     .fe1_pc            (fe1_pc[31:2]),
     .fe1_specid,
     .fe1_insn          (fe1_insn[31:0]),
     .ex_stall,
     .ex_specid,
     .ex_br_miss,
     .ex_br_taken,
     .ex_br_ntaken,
     .ex_fwd_data       (ex_fwd_data[31:0]),
     .mem0_fwd_data     (mem0_fwd_data[31:0]),
     .mem1_fwd_data     (mem1_fwd_data[31:0]),
     .csr_kill,
     .wb_valid,
     .wb_reg            (wb_reg[4:0]),
     .wb_data           (wb_data[31:0]),
     .fwd_stall,
     .fwd_rs1,
     .fwd_rs2);

  stage_execute execute
    (/*AUTOINST*/
     // Outputs
     .ex_specid,
     .ex_br_ntaken,
     .ex_br_taken,
     .ex_stall,
     .ex_br_miss,
     .ex_valid,
     .ex_exc,
     .ex_exc_cause,
     .ex_pc             (ex_pc[31:2]),
     .ex_data0          (ex_data0[31:0]),
     .ex_data1          (ex_data1[31:0]),
     .ex_mem_read,
     .ex_mem_write,
     .ex_mem_extend,
     .ex_mem_width      (ex_mem_width[1:0]),
     .ex_wb_reg         (ex_wb_reg[4:0]),
     .ex_fwd_valid,
     .ex_fwd_stall,
     .ex_fwd_data       (ex_fwd_data[31:0]),
     // Inputs
     .clk_core,
     .reset_n,
     .de_valid,
     .de_stall,
     .de_exc,
     .de_exc_cause,
     .de_pc             (de_pc[31:2]),
     .de_specid,
     .de_rdata1         (de_rdata1[31:0]),
     .de_rdata2         (de_rdata2[31:0]),
     .de_imm            (de_imm[31:0]),
     .de_use_pc,
     .de_use_imm,
     .de_sub_sra,
     .de_data1_sel,
     .de_op,
     .de_br,
     .de_br_inv,
     .de_br_pred,
     .de_jump,
     .de_br_misalign,
     .de_br_miss_misalign,
     .de_mem_read,
     .de_mem_write,
     .de_mem_extend,
     .de_mem_width      (de_mem_width[1:0]),
     .de_wb_reg         (de_wb_reg[4:0]),
     .mem0_stall,
     .csr_kill,
     .wb_exc);

  stage_memory0 memory0
    (/*AUTOINST*/
     // Outputs
     .mem0_stall,
     .mem0_fwd_valid,
     .mem0_fwd_stall,
     .mem0_fwd_data     (mem0_fwd_data[31:0]),
     .mem0_dc_read,
     .mem0_dc_trans,
     .mem0_dc_asid      (mem0_dc_asid[8:0]),
     .mem0_dc_addr      (mem0_dc_addr[31:2]),
     .mem0_valid,
     .mem0_exc,
     .mem0_exc_cause,
     .mem0_pc           (mem0_pc[31:2]),
     .mem0_mem1_req,
     .mem0_fe1_req,
     .mem0_read,
     .mem0_write,
     .mem0_extend,
     .mem0_width        (mem0_width[1:0]),
     .mem0_addr         (mem0_addr[31:0]),
     .mem0_wdata        (mem0_wdata[31:0]),
     .mem0_wb_reg       (mem0_wb_reg[4:0]),
     // Inputs
     .clk_core,
     .reset_n,
     .ex_valid,
     .ex_stall,
     .ex_exc,
     .ex_exc_cause,
     .ex_pc             (ex_pc[31:2]),
     .ex_data0          (ex_data0[31:0]),
     .ex_data1          (ex_data1[31:0]),
     .ex_mem_read,
     .ex_mem_write,
     .ex_mem_extend,
     .ex_mem_width      (ex_mem_width[1:0]),
     .ex_wb_reg         (ex_wb_reg[4:0]),
     .fe1_mem0_read,
     .fe1_mem0_addr     (fe1_mem0_addr[28:2]),
     .csr_kill,
     .csr_satp          (csr_satp[31:0]),
     .mem1_stall,
     .mem1_mem0_read,
     .mem1_mem0_trans,
     .mem1_mem0_addr    (mem1_mem0_addr[31:2]));

  stage_memory1 memory1
    (/*AUTOINST*/
     // Outputs
     .mem1_stall,
     .mem1_mem0_read,
     .mem1_mem0_trans,
     .mem1_mem0_addr    (mem1_mem0_addr[31:2]),
     .mem1_fwd_valid,
     .mem1_fwd_stall,
     .mem1_fwd_data     (mem1_fwd_data[31:0]),
     .mem1_tlb_write_req,
     .mem1_tlb_write_super,
     .mem1_tlb_write_tag(mem1_tlb_write_tag[31:21]),
     .mem1_tlb_write_asid(mem1_tlb_write_asid[8:0]),
     .mem1_tlb_write_ppn(mem1_tlb_write_ppn[28:12]),
     .mem1_tlb_write_flags(mem1_tlb_write_flags[7:0]),
     .mem1_cam_read_tag_in(mem1_cam_read_tag_in[28:12]),
     .mem1_cam_read_req,
     .mem1_cam_read_index(mem1_cam_read_index[11:2]),
     .mem1_cam_write_index(mem1_cam_write_index[11:2]),
     .mem1_cam_write_req_data,
     .mem1_cam_write_data(mem1_cam_write_data[31:0]),
     .mem1_cam_write_mask(mem1_cam_write_mask[3:0]),
     .mem1_cam_write_req_tag_flags,
     .mem1_cam_write_tag(mem1_cam_write_tag[28:12]),
     .mem1_cam_write_flags(mem1_cam_write_flags[1:0]),
     .mem1_cvalid,
     .mem1_cmd,
     .mem1_bus_addr     (mem1_bus_addr[28:2]),
     .mem1_wvalid,
     .mem1_wlast,
     .mem1_bus_wdata    (mem1_bus_wdata[31:0]),
     .mem1_wmask        (mem1_wmask[3:0]),
     .mem1_rready,
     .mem1_eack,
     .mem1_csr_addr     (mem1_csr_addr[11:0]),
     .mem1_csr_write    (mem1_csr_write[1:0]),
     .mem1_csr_din      (mem1_csr_din[31:0]),
     .mem1_read,
     .mem1_valid_wb,
     .mem1_exc,
     .mem1_exc_cause,
     .mem1_flush,
     .mem1_pc           (mem1_pc[31:2]),
     .mem1_wb_reg       (mem1_wb_reg[4:0]),
     .mem1_dout         (mem1_dout[31:0]),
     .mem1_valid_fe1,
     // Inputs
     .clk_core,
     .reset_n,
     .mem0_valid,
     .mem0_stall,
     .mem0_exc,
     .mem0_exc_cause,
     .mem0_pc           (mem0_pc[31:2]),
     .mem0_mem1_req,
     .mem0_fe1_req,
     .mem0_read,
     .mem0_write,
     .mem0_extend,
     .mem0_width        (mem0_width[1:0]),
     .mem0_addr         (mem0_addr[31:0]),
     .mem0_wdata        (mem0_wdata[31:0]),
     .mem0_wb_reg       (mem0_wb_reg[4:0]),
     .ex_br_miss,
     .dc_tlb_read_hit,
     .dc_tlb_read_super,
     .dc_tlb_read_ppn   (dc_tlb_read_ppn[28:12]),
     .dc_tlb_read_flags (dc_tlb_read_flags[7:0]),
     .dc_cam_read_hit,
     .dc_cam_read_tag_out(dc_cam_read_tag_out[28:12]),
     .dc_cam_read_data  (dc_cam_read_data[31:0]),
     .dc_cam_read_flags (dc_cam_read_flags[1:0]),
     .bmain_cready_mem1,
     .bmain_wready_mem1,
     .bmain_rvalid_mem1,
     .bmain_rlast,
     .bmain_rdata       (bmain_rdata[31:0]),
     .bmain_error_mem1,
     .csr_error,
     .csr_flush,
     .csr_dout          (csr_dout[31:0]),
     .csr_kill,
     .csr_satp          (csr_satp[31:0]),
     .wb_stall,
     .fe1_mem1_kill);

  stage_write write
    (/*AUTOINST*/
     // Outputs
     .wb_stall,
     .wb_reg            (wb_reg[4:0]),
     .wb_data           (wb_data[31:0]),
     .wb_valid,
     .wb_exc,
     .wb_exc_cause,
     .wb_flush,
     .wb_pc             (wb_pc[31:2]),
     // Inputs
     .clk_core,
     .reset_n,
     .mem1_valid_wb,
     .mem1_stall,
     .mem1_exc,
     .mem1_exc_cause,
     .mem1_flush,
     .mem1_pc           (mem1_pc[31:2]),
     .mem1_wb_reg       (mem1_wb_reg[4:0]),
     .mem1_dout         (mem1_dout[31:0]),
     .csr_kill);

  forward_unit fwd_unit
    (/*AUTOINST*/
     // Outputs
     .fwd_stall,
     .fwd_rs1,
     .fwd_rs2,
     // Inputs
     .de_rs1            (de_rs1[4:0]),
     .de_rs2            (de_rs2[4:0]),
     .ex_fwd_valid,
     .ex_fwd_stall,
     .ex_wb_reg         (ex_wb_reg[4:0]),
     .mem0_fwd_valid,
     .mem0_fwd_stall,
     .mem0_wb_reg       (mem0_wb_reg[4:0]),
     .mem1_fwd_valid,
     .mem1_fwd_stall,
     .mem1_wb_reg       (mem1_wb_reg[4:0]));

  csr csr
    (/*AUTOINST*/
     // Outputs
     .csr_error,
     .csr_flush,
     .csr_dout          (csr_dout[31:0]),
     .csr_kill,
     .csr_fe_inhibit,
     .csr_setpc,
     .csr_newpc         (csr_newpc[31:2]),
     .csr_satp          (csr_satp[31:0]),
     // Inputs
     .clk_core,
     .reset_n,
     .mem1_csr_addr     (mem1_csr_addr[11:0]),
     .mem1_csr_write    (mem1_csr_write[1:0]),
     .mem1_csr_din      (mem1_csr_din[31:0]),
     .wb_valid,
     .wb_stall,
     .wb_exc,
     .wb_exc_cause,
     .wb_flush,
     .wb_pc             (wb_pc[31:2]),
     .wb_data           (wb_data[31:0]));

  icache icache
    (/*AUTOINST*/
     // Outputs
     .ic_tlb_read_hit,
     .ic_tlb_read_super,
     .ic_tlb_read_ppn   (ic_tlb_read_ppn[28:12]),
     .ic_tlb_read_flags (ic_tlb_read_flags[7:0]),
     .ic_cam_read_hit,
     .ic_cam_read_tag_out(ic_cam_read_tag_out[28:12]),
     .ic_cam_read_data  (ic_cam_read_data[31:0]),
     .ic_cam_read_flags (ic_cam_read_flags[1:0]),
     // Inputs
     .clk_core,
     .reset_n,
     .fe0_read_req,
     .fe0_read_asid     (fe0_read_asid[8:0]),
     .fe0_read_addr     (fe0_read_addr[31:2]),
     .fe1_tlb_read_req,
     .fe1_tlb_read_asid (fe1_tlb_read_asid[8:0]),
     .fe1_tlb_read_addr (fe1_tlb_read_addr[31:12]),
     .fe1_tlb_write_req,
     .fe1_tlb_write_super,
     .fe1_tlb_write_tag (fe1_tlb_write_tag[31:21]),
     .fe1_tlb_write_asid(fe1_tlb_write_asid[8:0]),
     .fe1_tlb_write_ppn (fe1_tlb_write_ppn[28:12]),
     .fe1_tlb_write_flags(fe1_tlb_write_flags[7:0]),
     .fe1_cam_read_tag_in(fe1_cam_read_tag_in[28:12]),
     .fe1_cam_write_index(fe1_cam_write_index[11:2]),
     .fe1_cam_write_req_data,
     .fe1_cam_write_data(fe1_cam_write_data[31:0]),
     .fe1_cam_write_req_tag_flags,
     .fe1_cam_write_tag (fe1_cam_write_tag[28:12]),
     .fe1_cam_write_flags(fe1_cam_write_flags[1:0]));

  dcache dcache
    (/*AUTOINST*/
     // Outputs
     .dc_tlb_read_hit,
     .dc_tlb_read_super,
     .dc_tlb_read_ppn   (dc_tlb_read_ppn[28:12]),
     .dc_tlb_read_flags (dc_tlb_read_flags[7:0]),
     .dc_cam_read_hit,
     .dc_cam_read_tag_out(dc_cam_read_tag_out[28:12]),
     .dc_cam_read_data  (dc_cam_read_data[31:0]),
     .dc_cam_read_flags (dc_cam_read_flags[1:0]),
     // Inputs
     .clk_core,
     .reset_n,
     .mem0_dc_read,
     .mem0_dc_trans,
     .mem0_dc_asid      (mem0_dc_asid[8:0]),
     .mem0_dc_addr      (mem0_dc_addr[31:2]),
     .mem1_tlb_write_req,
     .mem1_tlb_write_super,
     .mem1_tlb_write_tag(mem1_tlb_write_tag[31:21]),
     .mem1_tlb_write_asid(mem1_tlb_write_asid[8:0]),
     .mem1_tlb_write_ppn(mem1_tlb_write_ppn[28:12]),
     .mem1_tlb_write_flags(mem1_tlb_write_flags[7:0]),
     .mem1_cam_read_tag_in(mem1_cam_read_tag_in[28:12]),
     .mem1_cam_read_req,
     .mem1_cam_read_index(mem1_cam_read_index[11:2]),
     .mem1_cam_write_index(mem1_cam_write_index[11:2]),
     .mem1_cam_write_req_data,
     .mem1_cam_write_data(mem1_cam_write_data[31:0]),
     .mem1_cam_write_mask(mem1_cam_write_mask[3:0]),
     .mem1_cam_write_req_tag_flags,
     .mem1_cam_write_tag(mem1_cam_write_tag[28:12]),
     .mem1_cam_write_flags(mem1_cam_write_flags[1:0]));

  bus_main bus_main
    (/*AUTOINST*/
     // Outputs
     .bmain_rlast,
     .bmain_rdata       (bmain_rdata[31:0]),
     .bmain_cready_fe1,
     .bmain_rvalid_fe1,
     .bmain_error_fe1,
     .bmain_cready_mem1,
     .bmain_wready_mem1,
     .bmain_rvalid_mem1,
     .bmain_error_mem1,
     .bmain_cmd,
     .bmain_addr        (bmain_addr[27:2]),
     .bmain_wlast,
     .bmain_wdata       (bmain_wdata[31:0]),
     .bmain_wmask       (bmain_wmask[3:0]),
     .bmain_cvalid_rom,
     .bmain_rready_rom,
     .bmain_eack_rom,
     .bmain_cvalid_flash,
     .bmain_wvalid_flash,
     .bmain_rready_flash,
     .bmain_eack_flash,
     .bmain_cvalid_bmmio,
     .bmain_wvalid_bmmio,
     .bmain_rready_bmmio,
     .bmain_eack_bmmio,
     .bmain_cvalid_dctl,
     .bmain_wvalid_dctl,
     .bmain_rready_dctl,
     .bmain_eack_dctl,
     // Inputs
     .clk_core,
     .reset_n,
     .fe1_cvalid,
     .fe1_cmd,
     .fe1_addr          (fe1_addr[28:2]),
     .fe1_rready,
     .fe1_eack,
     .mem1_cvalid,
     .mem1_cmd,
     .mem1_bus_addr     (mem1_bus_addr[28:2]),
     .mem1_wvalid,
     .mem1_wlast,
     .mem1_bus_wdata    (mem1_bus_wdata[31:0]),
     .mem1_wmask        (mem1_wmask[3:0]),
     .mem1_rready,
     .mem1_eack,
     .rom_cready,
     .rom_rvalid,
     .rom_rlast,
     .rom_rdata         (rom_rdata[31:0]),
     .rom_error,
     .flash_cready,
     .flash_wready,
     .flash_rvalid,
     .flash_rlast,
     .flash_rdata,
     .flash_error,
     .bmmio_cready,
     .bmmio_wready,
     .bmmio_rvalid,
     .bmmio_rdata       (bmmio_rdata[31:0]),
     .bmmio_error,
     .dctl_cready,
     .dctl_wready,
     .dctl_rvalid,
     .dctl_rlast,
     .dctl_rdata        (dctl_rdata[31:0]),
     .dctl_error);

  bus_mmio bus_mmio
    (/*AUTOINST*/
     // Outputs
     .bmmio_cready,
     .bmmio_wready,
     .bmmio_rvalid,
     .bmmio_rdata       (bmmio_rdata[31:0]),
     .bmmio_error,
     .bmmio_cmd,
     .bmmio_addr        (bmmio_addr[7:2]),
     .bmmio_wdata       (bmmio_wdata[31:0]),
     .bmmio_cvalid_lcd,
     .bmmio_wvalid_lcd,
     .bmmio_rready_lcd,
     .bmmio_eack_lcd,
     .bmmio_cvalid_spi,
     .bmmio_wvalid_spi,
     .bmmio_rready_spi,
     .bmmio_eack_spi,
     // Inputs
     .clk_core,
     .reset_n,
     .bmain_cvalid_bmmio,
     .bmain_cmd,
     .bmain_addr        (bmain_addr[11:2]),
     .bmain_wvalid_bmmio,
     .bmain_wdata       (bmain_wdata[31:0]),
     .bmain_rready_bmmio,
     .bmain_eack_bmmio,
     .lcd_cready,
     .lcd_wready,
     .lcd_rvalid,
     .lcd_rdata,
     .lcd_error,
     .spi_cready,
     .spi_wready,
     .spi_rvalid,
     .spi_rdata,
     .spi_error);

`ifndef DUMMY_DRAM
  dram_ctl dram_ctl
    (/*AUTOINST*/
     // Outputs
     .dctl_cready,
     .dctl_cvalid,
     .dctl_cmd          (dctl_cmd[2:0]),
     .dctl_addr         (dctl_addr[27:0]),
     .dctl_wready,
     .dctl_wvalid,
     .dctl_wlast,
     .dctl_wdata        (dctl_wdata[63:0]),
     .dctl_wmask        (dctl_wmask[7:0]),
     .dctl_rvalid,
     .dctl_rlast,
     .dctl_rdata        (dctl_rdata[31:0]),
     .dctl_error,
     // Inputs
     .clk_core,
     .reset_n,
     .mig_ui_clk,
     .mig_ui_reset,
     .bmain_cvalid_dctl,
     .bmain_cmd,
     .bmain_addr        (bmain_addr[27:2]),
     .mig_cready,
     .bmain_wvalid_dctl,
     .bmain_wlast,
     .bmain_wdata       (bmain_wdata[31:0]),
     .bmain_wmask       (bmain_wmask[3:0]),
     .mig_wready,
     .mig_rvalid,
     .mig_rlast,
     .mig_rdata,
     .bmain_rready_dctl);

  dram_mig dram_mig(
    .ddr3_addr          (ddr3_addr),
    .ddr3_ba            (ddr3_ba),
    .ddr3_ras_n         (ddr3_ras_n),
    .ddr3_cas_n         (ddr3_cas_n),
    .ddr3_we_n          (ddr3_we_n),
    .ddr3_reset_n       (ddr3_reset_n),
    .ddr3_ck_p          (ddr3_ck_p),
    .ddr3_ck_n          (ddr3_ck_n),
    .ddr3_cke           (ddr3_cke),
    .ddr3_cs_n          (ddr3_cs_n),
    .ddr3_dm            (ddr3_dm),
    .ddr3_odt           (ddr3_odt),
    .ddr3_dq            (ddr3_dq),
    .ddr3_dqs_n         (ddr3_dqs_n),
    .ddr3_dqs_p         (ddr3_dqs_p),

    .sys_clk_i          (clk_mig_sys),
    .clk_ref_i          (clk_mig_ref),
    .sys_rst            (reset_n),

    .ui_clk             (mig_ui_clk),
    .ui_clk_sync_rst    (mig_ui_reset),

    .app_rd_data_valid  (mig_rvalid),
    .app_rd_data_end    (mig_rlast),
    .app_rd_data        (mig_rdata),

    .app_en             (dctl_cvalid),
    .app_rdy            (mig_cready),
    .app_cmd            (dctl_cmd),
    .app_addr           (dctl_addr),

    .app_wdf_wren       (dctl_wvalid),
    .app_wdf_rdy        (mig_wready),
    .app_wdf_end        (dctl_wlast),
    .app_wdf_data       (dctl_wdata),
    .app_wdf_mask       (dctl_wmask),

    .device_temp        (),
    .init_calib_complete(),

    .app_sr_req         ('b0),
    .app_sr_active      (),
    .app_ref_req        ('b0),
    .app_ref_ack        (),
    .app_zq_req         ('b0),
    .app_zq_ack         ()
    );
`else
  dram_ctl_dummy dram_ctl
    (/*AUTOINST*/
     // Outputs
     .dctl_cready,
     .dctl_wready,
     .dctl_rvalid,
     .dctl_rlast,
     .dctl_rdata        (dctl_rdata[31:0]),
     .dctl_error,
     // Inputs
     .clk_core,
     .reset_n,
     .bmain_cvalid_dctl,
     .bmain_cmd,
     .bmain_addr        (bmain_addr[27:2]),
     .bmain_wvalid_dctl,
     .bmain_wlast,
     .bmain_wdata       (bmain_wdata[31:0]),
     .bmain_wmask       (bmain_wmask[3:0]),
     .bmain_rready_dctl);
`endif

  rom rom
    (/*AUTOINST*/
     // Outputs
     .rom_cready,
     .rom_rvalid,
     .rom_rlast,
     .rom_rdata         (rom_rdata[31:0]),
     .rom_error,
     // Inputs
     .clk_core,
     .reset_n,
     .bmain_cvalid_rom,
     .bmain_cmd,
     .bmain_addr        (bmain_addr[27:2]),
     .bmain_rready_rom,
     .bmain_eack_rom);

endmodule
