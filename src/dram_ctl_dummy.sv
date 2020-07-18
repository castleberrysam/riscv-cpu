`timescale 1ns/1ps

module dram_ctl_dummy(
  input logic         clk_core,
  input logic         reset_n,

  // command channel
  input logic         bmain_cvalid_dctl,
  output logic        dctl_cready,
  input logic         bmain_cmd,
  input logic [27:2]  bmain_addr,

  // write data channel
  input logic         bmain_wvalid_dctl,
  output logic        dctl_wready,
  input logic         bmain_wlast,
  input logic [31:0]  bmain_wdata,
  input logic [3:0]   bmain_wmask,

  // read data channel
  output logic        dctl_rvalid,
  input logic         bmain_rready_dctl,
  output logic        dctl_rlast,
  output logic [31:0] dctl_rdata,

  output logic        dctl_error
  );

  assign dctl_error = 0;

  logic cmd_beat, rdata_beat, wdata_beat;
  assign cmd_beat = bmain_cvalid_dctl & dctl_cready;
  assign rdata_beat = dctl_rvalid & bmain_rready_dctl;
  assign wdata_beat = bmain_wvalid_dctl & dctl_wready;

  logic read;
  assign read = cmd_valid & cmd & (~dctl_rvalid | bmain_rready_dctl);

  logic        cmd_valid;
  logic        cmd;
  logic [27:4] addr;
  logic [1:0]  offset;
  logic        last;
  always_ff @(posedge clk_core)
    if(~reset_n)
      cmd_valid <= 0;
    else if(cmd_beat) begin
      cmd_valid <= 1;
      cmd <= bmain_cmd;
      addr <= bmain_addr[27:4];
      offset <= 'd0;
    end else if(read | wdata_beat) begin
      if(last)
        cmd_valid <= 0;
      offset <= offset + 'd1;
    end

  always_ff @(posedge clk_core) begin
    dctl_rvalid <= cmd_valid & cmd;
    dctl_rlast <= last;
  end

  assign last = offset == 'd3;
  assign dctl_cready = ~cmd_valid | (last & (read | wdata_beat));
  assign dctl_wready = cmd_valid & ~cmd;

  logic [31:0] storage[0:67108863];

  always_ff @(posedge clk_core) begin
    if(read)
      dctl_rdata <= storage[{addr,offset}];
    if(wdata_beat)
      storage[{addr,offset}] <= bmain_wdata;
  end

endmodule
