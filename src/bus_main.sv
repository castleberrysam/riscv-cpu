`timescale 1ns/1ps

`include "defines.svh"

module bus_main(
  input logic         clk_core,
  input logic         reset_n,

  // master port common signals
  output logic        bmain_rlast,
  output logic [31:0] bmain_rdata,

  // fetch1 master port
  input logic         fe1_cvalid,
  output logic        bmain_cready_fe1,
  input logic         fe1_cmd,
  input logic [28:2]  fe1_addr,

  output logic        bmain_rvalid_fe1,
  input logic         fe1_rready,

  output logic        bmain_error_fe1,
  input logic         fe1_eack,

  // memory1 master port
  input logic         mem1_cvalid,
  output logic        bmain_cready_mem1,
  input logic         mem1_cmd,
  input logic [28:2]  mem1_bus_addr,

  input logic         mem1_wvalid,
  output logic        bmain_wready_mem1,
  input logic         mem1_wlast,
  input logic [31:0]  mem1_bus_wdata,
  input logic [3:0]   mem1_wmask,

  output logic        bmain_rvalid_mem1,
  input logic         mem1_rready,

  output logic        bmain_error_mem1,
  input logic         mem1_eack,

  // slave port common signals
  output logic        bmain_cmd,
  output logic [27:2] bmain_addr,

  output logic        bmain_wlast,
  output logic [31:0] bmain_wdata,
  output logic [3:0]  bmain_wmask,

  // rom slave port
  output logic        bmain_cvalid_rom,
  input logic         rom_cready,

  input logic         rom_rvalid,
  output logic        bmain_rready_rom,
  input logic         rom_rlast,
  input logic [31:0]  rom_rdata,

  input logic         rom_error,
  output logic        bmain_eack_rom,

  // flash slave port
  output logic        bmain_cvalid_flash,
  input logic         flash_cready,

  output logic        bmain_wvalid_flash,
  input logic         flash_wready,

  input logic         flash_rvalid,
  output logic        bmain_rready_flash,
  input logic         flash_rlast,
  input logic [31:0]  flash_rdata,

  input logic         flash_error,
  output logic        bmain_eack_flash,

  // mmio bus slave port
  output logic        bmain_cvalid_bmmio,
  input logic         bmmio_cready,

  output logic        bmain_wvalid_bmmio,
  input logic         bmmio_wready,

  input logic         bmmio_rvalid,
  output logic        bmain_rready_bmmio,
  input logic [31:0]  bmmio_rdata,

  input logic         bmmio_error,
  output logic        bmain_eack_bmmio,

  // dram_ctl slave port
  output logic        bmain_cvalid_dctl,
  input logic         dctl_cready,

  output logic        bmain_wvalid_dctl,
  input logic         dctl_wready,

  input logic         dctl_rvalid,
  output logic        bmain_rready_dctl,
  input logic         dctl_rlast,
  input logic [31:0]  dctl_rdata,

  input logic         dctl_error,
  output logic        bmain_eack_dctl
  );

  // command channel
  logic cmd_beat_fe1, cmd_beat_mem1, cmd_beat_in;
  assign cmd_beat_fe1 = fe1_cvalid & bmain_cready_fe1;
  assign cmd_beat_mem1 = mem1_cvalid & bmain_cready_mem1;
  assign cmd_beat_in = cmd_beat_fe1 | cmd_beat_mem1;

  logic cmd_beat_rom, cmd_beat_flash, cmd_beat_bmmio, cmd_beat_dctl, cmd_beat_out;
  assign cmd_beat_rom = bmain_cvalid_rom & rom_cready;
  assign cmd_beat_flash = bmain_cvalid_flash & flash_cready;
  assign cmd_beat_bmmio = bmain_cvalid_bmmio & bmmio_cready;
  assign cmd_beat_dctl = bmain_cvalid_dctl & dctl_cready;
  assign cmd_beat_out = cmd_beat_rom | cmd_beat_flash | cmd_beat_bmmio | cmd_beat_dctl;

  logic        cmd_in;
  logic [28:2] addr_in;
  always_comb
    if(mem1_cvalid) begin
      cmd_in = mem1_cmd;
      addr_in = mem1_bus_addr;
    end else begin
      cmd_in = fe1_cmd;
      addr_in = fe1_addr;
    end

  logic        cmd_valid, cmd_done;
  logic        cmd, cmd_src;
  logic [28:2] addr;
  always_ff @(posedge clk_core)
    if(~reset_n)
      cmd_valid <= 0;
    else if(cmd_beat_in) begin
      cmd_valid <= 1;
      cmd <= cmd_in;
      cmd_src <= mem1_cvalid;
      addr <= addr_in;
    end else if(cmd_done)
      cmd_valid <= 0;

  logic cmd_sent;
  always_ff @(posedge clk_core)
    if(cmd_beat_in)
      cmd_sent <= 0;
    else if(cmd_beat_out)
      cmd_sent <= 1;

  // address space:
  // 00000000-0000ffff: 64KiB block rom
  // 01000000-01ffffff: 16MiB QSPI flash
  // 02000000-02000fff: mmio peripherals
  // 10000000-1fffffff: 256MiB DDR3 dram
  // accessing any other address raises an error (access fault)
  struct packed {
    logic rom, flash, bmmio, dctl, none;
  } sel;
  always_comb begin
    sel = '{default:0};
    if(cmd_valid)
      unique casez({addr,2'b0})
        'h0000????: sel.rom = 1;
        'h01??????: sel.flash = 1;
        'h02000???: sel.bmmio = 1;
        'h1???????: sel.dctl = 1;
        default: sel.none = 1;
      endcase
  end
  
  logic rdata_done, wdata_done;
  assign rdata_done = rdata_beat_in & rlast_in;
  assign wdata_done = wdata_beat_out & mem1_wlast;
  assign cmd_done = cmd_valid & (cmd ? rdata_done : wdata_done);

  assign bmain_cready_fe1 = ~mem1_cvalid & (~cmd_valid | cmd_done);
  assign bmain_cready_mem1 = ~cmd_valid | cmd_done;
  assign bmain_cvalid_rom = sel.rom & ~cmd_sent;
  assign bmain_cvalid_flash = sel.flash & ~cmd_sent;
  assign bmain_cvalid_bmmio = sel.bmmio & ~cmd_sent;
  assign bmain_cvalid_dctl = sel.dctl & ~cmd_sent;
  assign bmain_cmd = cmd;
  assign bmain_addr = addr[27:2];

  // write data channel
  logic wdata_beat_mem1, wdata_beat_in;
  assign wdata_beat_mem1 = mem1_wvalid & bmain_wready_mem1;
  assign wdata_beat_in = wdata_beat_mem1;

  logic wdata_beat_flash, wdata_beat_bmmio, wdata_beat_dctl, wdata_beat_out;
  assign wdata_beat_flash = bmain_wvalid_flash & flash_wready;
  assign wdata_beat_bmmio = bmain_wvalid_bmmio & bmmio_wready;
  assign wdata_beat_dctl = bmain_wvalid_dctl & dctl_wready;
  assign wdata_beat_out = wdata_beat_flash | wdata_beat_bmmio | wdata_beat_dctl;

  logic        wdata_valid;
  logic        wlast;
  logic [31:0] wdata;
  logic [3:0]  wmask;
  always_ff @(posedge clk_core)
    if(~reset_n)
      wdata_valid <= 0;
    else if(wdata_beat_in) begin
      wlast <= mem1_wlast;
      wdata <= mem1_bus_wdata;
      wmask <= mem1_wmask;
    end else if(wdata_beat_out)
      wdata_valid <= 0;

  assign bmain_wready_mem1 = ~wdata_valid | wdata_beat_out;
  assign bmain_wvalid_flash = sel.flash & ~cmd & wdata_valid;
  assign bmain_wvalid_bmmio = sel.bmmio & ~cmd & wdata_valid;
  assign bmain_wvalid_dctl = sel.dctl & ~cmd & wdata_valid;
  assign bmain_wlast = wlast;
  assign bmain_wdata = wdata;
  assign bmain_wmask = wmask;

  // read data channel
  logic rdata_beat_rom, rdata_beat_flash, rdata_beat_bmmio, rdata_beat_dctl, rdata_beat_in;
  assign rdata_beat_rom = rom_rvalid & bmain_rready_rom;
  assign rdata_beat_flash = flash_rvalid & bmain_rready_flash;
  assign rdata_beat_bmmio = bmmio_rvalid & bmain_rready_bmmio;
  assign rdata_beat_dctl = dctl_rvalid & bmain_rready_dctl;
  assign rdata_beat_in = rdata_beat_rom | rdata_beat_flash | rdata_beat_bmmio | rdata_beat_dctl;

  logic rdata_beat_fe1, rdata_beat_mem1, rdata_beat_out;
  assign rdata_beat_fe1 = bmain_rvalid_fe1 & fe1_rready;
  assign rdata_beat_mem1 = bmain_rvalid_mem1 & mem1_rready;
  assign rdata_beat_out = rdata_beat_fe1 | rdata_beat_mem1;

  logic        rvalid;
  logic        rlast_in;
  logic [31:0] rdata_in;
  always_comb
    unique case(1)
      sel.rom: begin
        rvalid = rom_rvalid;
        rlast_in = rom_rlast;
        rdata_in = rom_rdata;
      end

      sel.flash: begin
        rvalid = flash_rvalid;
        rlast_in = flash_rlast;
        rdata_in = flash_rdata;
      end

      sel.bmmio: begin
        rvalid = bmmio_rvalid;
        rlast_in = 1;
        rdata_in = bmmio_rdata;
      end

      sel.dctl: begin
        rvalid = dctl_rvalid;
        rlast_in = dctl_rlast;
        rdata_in = dctl_rdata;
      end

      default: begin
        rvalid = 0;
        rlast_in = 0;
        rdata_in = '0;
      end
    endcase

  logic        rdata_valid;
  logic        rlast;
  logic [31:0] rdata;
  always_ff @(posedge clk_core)
    if(~reset_n)
      rdata_valid <= 0;
    else if(rdata_beat_in) begin
      rdata_valid <= 1;
      rlast <= rlast_in;
      rdata <= rdata_in;
    end else if(rdata_beat_out)
      rdata_valid <= 0;

  logic rready;
  assign rready = cmd & (~rdata_valid | rdata_beat_out);
  assign bmain_rready_rom = sel.rom & rready;
  assign bmain_rready_flash = sel.flash & rready;
  assign bmain_rready_bmmio = sel.bmmio & rready;
  assign bmain_rready_dctl = sel.dctl & rready;
  assign bmain_rvalid_fe1 = rdata_valid & ~cmd_src;
  assign bmain_rvalid_mem1 = rdata_valid & cmd_src;
  assign bmain_rlast = rlast;
  assign bmain_rdata = rdata;

  // TODO error signal
  assign bmain_error_fe1 = 0;
  assign bmain_error_mem1 = 0;
  assign bmain_eack_rom = 0;
  assign bmain_eack_flash = 0;
  assign bmain_eack_bmmio = 0;
  assign bmain_eack_dctl = 0;

endmodule
