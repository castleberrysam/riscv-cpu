`timescale 1ns/1ps
`default_nettype none

module sram(
  input wire                clk,
  input wire                reset_n,

  // read port
  input wire                read_req,
  input wire [LOGDEPTH-1:0] read_addr,
  output reg [31:0]         read_data,

  // write port
  input wire                write_req,
  input wire [LOGDEPTH-1:0] write_addr,
  input wire [3:0]          write_byte_en,
  input wire [31:0]         write_data
  );

    parameter DEPTH = 1024;
    localparam LOGDEPTH = $clog2(DEPTH);

    `include "defines.vh"

    reg [31:0] storage[0:DEPTH-1];

    // init data
    `ifdef XILINX
    initial
      $readmemb("sram.mif", storage);
    `else
    `ifndef SYNTHESIS
    integer j;
    reg [8*32:1] memfile;
    reg [31:0] fd;
    reg [640:1] error;
    initial
      begin
          for(j=0;j<DEPTH;j=j+1)
            storage[j] = 32'b0;

          if(!$value$plusargs("memfile=%s", memfile))
            memfile = "memory.hex";

          fd = $fopen(memfile, "r");
          if(fd == 32'b0)
            begin
                $fdisplay(STDERR, "Cannot open memfile %0s: error %0d (%0s)", memfile, $ferror(fd, error), error);
                $finish;
            end
          $fclose(fd);

          $readmemh(memfile, storage);
      end
    `endif
    `endif

    // read port
    always @(posedge clk)
      if(read_req)
        read_data <= storage[read_addr];

    // write port
    integer i;
    always @(posedge clk)
      if(write_req)
        for(i=0;i<4;i=i+1)
          if(write_byte_en[i])
            storage[write_addr][i*8+:8] <= write_data[i*8+:8];

endmodule
