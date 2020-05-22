`timescale 1ns/1ps
`default_nettype none

module memory(
  input             clk,
  input             reset_n,

  // inputs/outputs to fetch stage
  input             fe_req,
  input [31:0]      fe_addr,
  output            fe_ack,
  output reg [31:0] fe_data,

  // inputs/outputs to mem stage
  input             mem_req,
  input [31:0]      mem_addr,
  input             mem_write,
  input [31:0]      mem_data_in,
  input             mem_extend,
  input [1:0]       mem_width,
  output            mem_ack,
  output reg [31:0] mem_data_out
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

    function [31:0] extract(
      input [31:0] value,
      input [1:0] offset,
      input [1:0] width,
      input extend
      );
        case(width)
          2'b00:
            begin
                case(offset)
                  2'b00: extract = value[7:0];
                  2'b01: extract = value[15:8];
                  2'b10: extract = value[23:16];
                  2'b11: extract = value[31:24];
                endcase
                extract[31:8] = extend ? {24{extract[7]}} : 24'b0;
            end
          2'b01:
            begin
                extract = offset[1] ? value[31:16] : value[15:0];
                extract[31:16] = extend ? {16{extract[15]}} : 16'b0;
            end
          2'b10, 2'b11:
            extract = value;
        endcase
    endfunction

    assign fe_ack = fe_req & ~mem_req;
    assign mem_ack = mem_req;

    // read port
    always @(posedge clk)
      if(~reset_n)
        begin
            fe_data <= 32'b0;
            mem_data_out <= 32'b0;
        end
      else if(mem_req & ~mem_write)
        mem_data_out <= extract(storage[mem_addr[15:2]], mem_addr[1:0], mem_width, mem_extend);
      else if(fe_req)
        fe_data <= storage[fe_addr[15:2]];

    function [31:0] insert(
      input [31:0] value0,
      input [31:0] value1,
      input [1:0]  offset,
      input [1:0]  width
      );
        begin
            insert = value0;
            case(width)
              2'b00:
                case(offset)
                  2'b00: insert[7:0] = value1[7:0];
                  2'b01: insert[15:8] = value1[7:0];
                  2'b10: insert[23:16] = value1[7:0];
                  2'b11: insert[31:24] = value1[7:0];
                endcase
              2'b01:
                if(offset[1])
                  insert[31:16] = value1[15:0];
                else
                  insert[15:0] = value1[15:0];
              2'b10, 2'b11:
                insert = value1;
            endcase // case (width)
        end
    endfunction

    // write port
    always @(posedge clk)
      if(~reset_n)
        ;
      else if(mem_req & mem_write)
        storage[mem_addr[15:2]] <= insert(storage[mem_addr[15:2]], mem_data_in, mem_addr[1:0], mem_width);

endmodule
