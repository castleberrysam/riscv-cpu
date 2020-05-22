`timescale 1ns/1ps
`default_nettype none

module memory(
  input             clk,
  input             reset_n,

  input             req,
  input [31:0]      addr,
  input             write_in,
  input [31:0]      data_in,
  input             extend,
  input [1:0]       width,

  // outputs
  output reg        ack,
  output reg [31:0] data_out
  );

    `include "defines.vh"

    reg [31:0] storage[0:16383];

    `ifndef SYNTHESIS
    integer i;
    reg [8*32:1] memfile;
    reg [31:0] fd;
    reg [640:1] error;
    initial
      begin
          for(i=0;i<16384;i=i+1)
            storage[i] = 32'b0;

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

    function [31:0] read(
      input [31:0] addr,
      input [1:0] width,
      input extend
      );
        reg [31:0] data;
        reg [7:0] data_byte;
        reg [15:0] data_word;
        begin
            data = storage[addr[15:2]];
            case(width)
              2'b00:
                begin
                    case(addr[1:0])
                      2'b00: data_byte = data[7:0];
                      2'b01: data_byte = data[15:8];
                      2'b10: data_byte = data[23:16];
                      2'b11: data_byte = data[31:24];
                    endcase
                    read = extend ? {{24{data_byte[7]}},data_byte} : {24'b0,data_byte};
                end
              2'b01:
                begin
                    data_word = addr[1] ? data[31:16] : data[15:0];
                    read = extend ? {{16{data_word[15]}},data_word} : {16'b0,data_word};
                end
              2'b10, 2'b11:
                read = data;
            endcase
        end
    endfunction

    function [31:0] write(
      input [31:0] addr,
      input [31:0] data_in,
      input [1:0] width
      );
        reg [31:0] data;
        begin
            data = storage[addr[15:2]];
            case(width)
              2'b00:
                case(addr[1:0])
                  2'b00: data[7:0] = data_in[7:0];
                  2'b01: data[15:8] = data_in[7:0];
                  2'b10: data[23:16] = data_in[7:0];
                  2'b11: data[31:24] = data_in[7:0];
                endcase
              2'b01:
                if(addr[1])
                  data[31:16] = data_in[15:0];
                else
                  data[15:0] = data_in[15:0];
              2'b10, 2'b11:
                data = data_in;
            endcase
            write = data;
        end
    endfunction

    always @(posedge clk)
      if(~reset_n)
        ack <= 0;
      else if(req & ~ack)
        begin
            ack <= 1;
            if(write_in)
              storage[addr[15:2]] <= write(addr, data_in, width);
            else
              data_out <= read(addr, width, extend);
        end
      else
        ack <= 0;

endmodule
