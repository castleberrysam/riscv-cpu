`timescale 1ns/1ps

module dram_ctl(
  input logic         clk_core,
  input logic         reset_n,

  input logic         mig_ui_clk,
  input logic         mig_ui_reset,

  // command channel
  input logic         bmain_cvalid_dctl,
  output logic        dctl_cready,
  input logic         bmain_cmd,
  input logic [27:2]  bmain_addr,

  output logic        dctl_cvalid,
  input logic         mig_cready,
  output logic [2:0]  dctl_cmd,
  output logic [27:0] dctl_addr,

  // write data channel
  input logic         bmain_wvalid_dctl,
  output logic        dctl_wready,
  input logic         bmain_wlast,
  input logic [31:0]  bmain_wdata,
  input logic [3:0]   bmain_wmask,

  output logic        dctl_wvalid,
  input logic         mig_wready,
  output logic        dctl_wlast,
  output logic [63:0] dctl_wdata,
  output logic [7:0]  dctl_wmask,

  // read data channel
  // the mig does not provide a ready input on this channel :(
  input logic         mig_rvalid,
  input logic         mig_rlast,
  input logic [63:0]  mig_rdata,

  output logic        dctl_rvalid,
  input logic         bmain_rready_dctl,
  output logic        dctl_rlast,
  output logic [31:0] dctl_rdata,

  output logic        dctl_error
  );

  logic dctl_reset_n;
  assign dctl_reset_n = ~(~reset_n | mig_ui_reset);

  assign dctl_addr[1:0] = '0;
  assign dctl_error = 0;

  // rdata syncro
  logic        rdata_empty, rdata_afull;
  logic        rdata_fifo_read;
  logic        rdata_fifo_rlast;
  logic [63:0] rdata_fifo_rdata;
  async_fifo #(
    .WIDTH(64+1),
    .AFULL_OFF(13'h008)
    ) rdata_fifo(
    .reset_n(dctl_reset_n),

    .full(),
    .empty(rdata_empty),
    .afull(rdata_afull),
    .aempty(),

    .read_clk(clk_core),
    .read_req(rdata_fifo_read),
    .read_data({rdata_fifo_rlast,rdata_fifo_rdata}),

    .write_clk(mig_ui_clk),
    .write_req(mig_rvalid),
    .write_data({mig_rlast,mig_rdata})
    );

  logic rdata_beat;
  assign rdata_beat = dctl_rvalid & bmain_rready_dctl;

  logic rdata_word_sel;
  always_ff @(posedge clk_core)
    if(~dctl_reset_n)
      rdata_word_sel <= 0;
    else if(rdata_beat)
      rdata_word_sel <= ~rdata_word_sel;

  assign dctl_rlast = rdata_fifo_rlast & rdata_word_sel;
  assign dctl_rdata = rdata_word_sel ? rdata_fifo_rdata[63:32] : rdata_fifo_rdata[31:0];

  always_ff @(posedge clk_core)
    if(~dctl_reset_n)
      dctl_rvalid <= 0;
    else if(rdata_fifo_read)
      dctl_rvalid <= 1;
    else if(rdata_beat & rdata_word_sel)
      dctl_rvalid <= 0;

  assign rdata_fifo_read = ~rdata_empty & (~dctl_rvalid | (rdata_beat & rdata_word_sel));

  // cmd syncro
  assign dctl_cmd[2:1] = '0;

  logic cmd_full, cmd_empty;
  logic cmd_fifo_read;
  async_fifo #(
    .WIDTH(26+1)
    ) cmd_fifo(
    .reset_n(dctl_reset_n),

    .full(cmd_full),
    .empty(cmd_empty),
    .afull(),
    .aempty(),

    .read_clk(mig_ui_clk),
    .read_req(cmd_fifo_read),
    .read_data({dctl_cmd[0],dctl_addr[27:2]}),

    .write_clk(clk_core),
    .write_req(bmain_cvalid_dctl & dctl_cready),
    .write_data({bmain_cmd,bmain_addr})
    );

  logic cmd_beat;
  assign cmd_beat = dctl_cvalid & mig_cready;

  logic cmd_valid;
  always_ff @(posedge mig_ui_clk)
    if(~dctl_reset_n)
      cmd_valid <= 0;
    else if(cmd_fifo_read)
      cmd_valid <= 1;
    else if(cmd_beat)
      cmd_valid <= 0;

  assign dctl_cready = ~cmd_full;
  assign dctl_cvalid = cmd_valid & ~dctl_wlast & (dctl_cmd[0] | wdata_mig_beat) & ~rdata_afull;
  assign cmd_fifo_read = ~cmd_empty & (~cmd_valid | cmd_beat);

  // wdata syncro
  logic        wdata_empty, wdata_afull;
  logic        wdata_fifo_read, wdata_fifo_write;
  logic [31:0] bmain_wdata_r;
  logic [3:0]  bmain_wmask_r;
  async_fifo #(
    .WIDTH(64+8),
    .AEMPTY_OFF(13'h002),
    .AFULL_OFF(13'h002)
    ) wdata_fifo(
    .reset_n(dctl_reset_n),

    .full(),
    .empty(wdata_empty),
    .afull(wdata_afull),
    .aempty(),

    .read_clk(mig_ui_clk),
    .read_req(wdata_fifo_read),
    .read_data({dctl_wdata,dctl_wmask}),

    .write_clk(clk_core),
    .write_req(wdata_fifo_write),
    .write_data({bmain_wdata,bmain_wdata_r,bmain_wmask,bmain_wmask_r})
    );

  logic wdata_bus_beat, wdata_mig_beat;
  assign wdata_bus_beat = bmain_wvalid_dctl & dctl_wready;
  assign wdata_mig_beat = dctl_wvalid & mig_wready;

  logic wdata_word_sel;
  always_ff @(posedge clk_core)
    if(~dctl_reset_n)
      wdata_word_sel <= 0;
    else if(wdata_bus_beat)
      wdata_word_sel <= ~wdata_word_sel;

  assign wdata_fifo_write = wdata_bus_beat & wdata_word_sel;
  always_ff @(posedge clk_core)
    if(wdata_bus_beat & ~wdata_word_sel) begin
      bmain_wdata_r <= bmain_wdata;
      bmain_wmask_r <= bmain_wmask;
    end

  always_ff @(posedge mig_ui_clk)
    if(~dctl_reset_n)
      dctl_wlast <= 0;
    else if(wdata_mig_beat)
      dctl_wlast <= ~dctl_wlast;

  logic wdata_valid;
  always_ff @(posedge mig_ui_clk)
    if(~dctl_reset_n)
      wdata_valid <= 0;
    else if(wdata_fifo_read)
      wdata_valid <= 1;
    else if(wdata_mig_beat)
      wdata_valid <= 0;

  assign dctl_wready = ~wdata_afull;
  assign dctl_wvalid = wdata_valid & (dctl_wlast | (~dctl_cmd[0] & ~rdata_afull)) & ~wdata_empty;
  assign wdata_fifo_read = ~wdata_empty & (~wdata_valid | wdata_mig_beat);

endmodule
