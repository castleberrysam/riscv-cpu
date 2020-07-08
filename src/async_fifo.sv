`timescale 1ns/1ps

module async_fifo(
  input logic              reset_n,

  output logic             aempty,
  output logic             afull,
  output logic             empty,
  output logic             full,

  input logic              read_clk,
  input logic              read_req,
  output logic [WIDTH-1:0] read_data,

  input logic              write_clk,
  input logic              write_req,
  input logic [WIDTH-1:0]  write_data
  );

  // must be <= 72
  parameter WIDTH = 8;
  // must be specified in hex
  parameter AEMPTY_OFF = 13'h0001;
  parameter AFULL_OFF = 13'h0001;

  FIFO_DUALCLOCK_MACRO #(
    .DATA_WIDTH(WIDTH),
    .ALMOST_EMPTY_OFFSET(AEMPTY_OFF),
    .ALMOST_FULL_OFFSET(AFULL_OFF),
    .DEVICE("7SERIES")
    ) fifo (
    .RST(~reset_n),

    // read port
    .RDCLK(read_clk),
    .RDEN(read_req),
    .RDCOUNT(),
    .RDERR(),
    .DO(read_data),

    // write port
    .WRCLK(write_clk),
    .WREN(write_req),
    .WRCOUNT(),
    .WRERR(),
    .DI(write_data),

    // status flags
    .ALMOSTEMPTY(aempty),
    .ALMOSTFULL(afull),
    .EMPTY(empty),
    .FULL(full)
    );

endmodule
