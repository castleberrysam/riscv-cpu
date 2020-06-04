`timescale 1ns/1ps

`include "defines.svh"

module sram(
  input logic                clk,
  input logic                reset_n,

  // read port
  input logic                read_req,
  input logic [LOGDEPTH-1:0] read_addr,
  output logic [31:0]        read_data,

  // write port
  input logic                write_req,
  input logic [LOGDEPTH-1:0] write_addr,
  input logic [3:0]          write_byte_en,
  input logic [31:0]         write_data
  );

  parameter DEPTH = 1024;
  localparam LOGDEPTH = $clog2(DEPTH);

  logic [31:0] storage[0:DEPTH-1];

  // init data
`ifdef SYNTHESIS
`ifdef XILINX
  initial
    $readmemb("sram.mif", storage);
`endif
`else
  logic [8*32:1] memfile;
  logic [31:0] fd;
  logic [640:1] error;
  initial begin
    for(int j=0;j<DEPTH;j++)
      storage[j] = 0;

    if(!$value$plusargs("memfile=%s", memfile))
      memfile = "memory.hex";

    fd = $fopen(memfile, "r");
    if(fd == 0) begin
      $fdisplay(STDERR, "Cannot open memfile %0s: error %0d (%0s)", memfile, $ferror(fd, error), error);
      $finish;
    end
    $fclose(fd);

    $readmemh(memfile, storage);
  end
`endif

  // read port
  always @(posedge clk)
    if(read_req)
      read_data <= storage[read_addr];

  // write port
  always @(posedge clk)
    if(write_req)
      for(int i=0;i<4;i++)
        if(write_byte_en[i])
          storage[write_addr][i*8+:8] <= write_data[i*8+:8];

endmodule
