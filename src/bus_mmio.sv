`timescale 1ns/1ps

module bus_mmio(
  input logic         clk_core,
  input logic         reset_n,

  // main bus master port
  input logic         bmain_cvalid_bmmio,
  output logic        bmmio_cready,
  input logic         bmain_cmd,
  input logic [11:2]  bmain_addr,

  input logic         bmain_wvalid_bmmio,
  output logic        bmmio_wready,
  input logic [31:0]  bmain_wdata,

  output logic        bmmio_rvalid,
  input logic         bmain_rready_bmmio,
  output logic [31:0] bmmio_rdata,

  output logic        bmmio_error,
  input logic         bmain_eack_bmmio,

  // slave port common signals
  output logic        bmmio_cmd,
  output logic [7:2]  bmmio_addr,

  output logic [31:0] bmmio_wdata,

  // lcd slave port
  output logic        bmmio_cvalid_lcd,
  input logic         lcd_cready,

  output logic        bmmio_wvalid_lcd,
  input logic         lcd_wready,

  input logic         lcd_rvalid,
  output logic        bmmio_rready_lcd,
  input logic [31:0]  lcd_rdata,

  input logic         lcd_error,
  output logic        bmmio_eack_lcd,

  // spi_master slave port
  output logic        bmmio_cvalid_spi,
  input logic         spi_cready,

  output logic        bmmio_wvalid_spi,
  input logic         spi_wready,

  input logic         spi_rvalid,
  output logic        bmmio_rready_spi,
  input logic [31:0]  spi_rdata,

  input logic         spi_error,
  output logic        bmmio_eack_spi
  );

  // command channel
  logic cmd_beat_in;
  assign cmd_beat_in = bmain_cvalid_bmmio & bmmio_cready;

  logic cmd_beat_lcd, cmd_beat_spi, cmd_beat_out;
  assign cmd_beat_lcd = bmmio_cvalid_lcd & lcd_cready;
  assign cmd_beat_spi = bmmio_cvalid_spi & spi_cready;
  assign cmd_beat_out = cmd_beat_lcd | cmd_beat_spi;

  logic        cmd_valid, cmd_done;
  logic        cmd;
  logic [11:2] addr;
  always_ff @(posedge clk_core)
    if(~reset_n)
      cmd_valid <= 0;
    else if(cmd_beat_in) begin
      cmd_valid <= 1;
      cmd <= bmain_cmd;
      addr <= bmain_addr;
    end else if(cmd_done)
      cmd_valid <= 0;

  assign cmd_done = cmd_valid & (cmd ? rdata_beat_in : wdata_beat_out);

  logic cmd_sent;
  always_ff @(posedge clk_core)
    if(cmd_beat_in)
      cmd_sent <= 0;
    else if(cmd_beat_out)
      cmd_sent <= 1;

  // address space:
  // 000-0ff: lcd controller
  // 100-1ff: spi master (for SD card)
  // accessing any other address raises an error (access fault)
  struct packed {
    logic lcd, spi, none;
  } sel;
  always_comb begin
    sel = '{default:0};
    if(cmd_valid)
      unique casez(addr)
        'h0??: sel.lcd = 1;
        'h1??: sel.spi = 1;
        default: sel.none = 1;
      endcase
  end

  assign bmmio_cready = ~cmd_valid | cmd_beat_out;
  assign bmmio_cvalid_lcd = sel.lcd & ~cmd_sent;
  assign bmmio_cvalid_spi = sel.spi & ~cmd_sent;
  assign bmmio_cmd = cmd;
  assign bmmio_addr = addr[7:2];

  // write data channel
  logic wdata_beat_in;
  assign wdata_beat_in = bmain_wvalid_bmmio & bmmio_wready;

  logic wdata_beat_lcd, wdata_beat_spi, wdata_beat_out;
  assign wdata_beat_lcd = bmmio_wvalid_lcd & lcd_wready;
  assign wdata_beat_spi = bmmio_wvalid_spi & spi_wready;
  assign wdata_beat_out = wdata_beat_lcd | wdata_beat_spi;

  logic        wdata_valid;
  logic [31:0] wdata;
  always_ff @(posedge clk_core)
    if(~reset_n)
      wdata_valid <= 0;
    else if(wdata_beat_in) begin
      wdata_valid <= 1;
      wdata <= bmain_wdata;
    end else if(wdata_beat_out)
      wdata_valid <= 0;

  assign bmmio_wready = ~wdata_valid | wdata_beat_out;
  assign bmmio_wvalid_lcd = sel.lcd & ~cmd & wdata_valid;
  assign bmmio_wvalid_spi = sel.spi & ~cmd & wdata_valid;
  assign bmmio_wdata = wdata;

  // read data channel
  logic rdata_beat_lcd, rdata_beat_spi, rdata_beat_in;
  assign rdata_beat_lcd = lcd_rvalid & bmmio_rready_lcd;
  assign rdata_beat_spi = spi_rvalid & bmmio_rready_spi;
  assign rdata_beat_in = rdata_beat_lcd | rdata_beat_spi;

  logic rdata_beat_out;
  assign rdata_beat_out = bmmio_rvalid & bmain_rready_bmmio;

  logic [31:0] rdata_in;
  always_comb
    unique case(1)
      sel.lcd: rdata_in = lcd_rdata;
      sel.spi: rdata_in = spi_rdata;
      default: rdata_in = '0;
    endcase

  logic        rdata_valid;
  logic [31:0] rdata;
  always_ff @(posedge clk_core)
    if(~reset_n)
      rdata_valid <= 0;
    else if(rdata_beat_in) begin
      rdata_valid <= 1;
      rdata <= rdata_in;
    end else if(rdata_beat_out)
      rdata_valid <= 0;

  logic rready;
  assign rready = cmd & (~rdata_valid | rdata_beat_out);
  assign bmmio_rready_lcd = sel.lcd & rready;
  assign bmmio_rready_spi = sel.spi & rready;
  assign bmmio_rvalid = rdata_valid;
  assign bmmio_rdata = rdata;

  // error signal
  assign bmmio_error = lcd_error | spi_error;
  assign bmmio_eack_lcd = bmain_eack_bmmio;
  assign bmmio_eack_spi = bmain_eack_bmmio;

endmodule
