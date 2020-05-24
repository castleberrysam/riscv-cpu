`timescale 1ns/1ps
`default_nettype none

module memory(
  input wire         clk,
  input wire         reset_n,

  // inputs/outputs to fetch stage
  input wire         fe_req,
  input wire [31:0]  fe_addr,
  output wire        fe_ack,
  output wire [31:0] fe_data,

  // inputs/outputs to mem stage
  input wire         mem_req,
  input wire [31:0]  mem_addr,
  input wire         mem_write,
  input wire [31:0]  mem_data_in,
  input wire         mem_extend,
  input wire [1:0]   mem_width,
  output wire        mem_ack,
  output wire [31:0] mem_data_out
  );

    `include "defines.vh"

    assign fe_ack = fe_req & ~mem_req;
    assign mem_ack = mem_req;

    reg [3:0] byte_en;
    always @(*)
      casez({mem_width,mem_addr[1:0]})
        4'b0000: byte_en = 4'b0001;
        4'b0001: byte_en = 4'b0010;
        4'b0010: byte_en = 4'b0100;
        4'b0011: byte_en = 4'b1000;

        4'b010?: byte_en = 4'b0011;
        4'b011?: byte_en = 4'b1100;

        4'b1???: byte_en = 4'b1111;
      endcase

    wire [13:0] read_addr = (mem_req & ~mem_write) ? mem_addr[15:2] : fe_addr[15:2];
    wire [31:0] read_data;
    sram #(
      .DEPTH(16384)
      ) sram(
      .clk(clk),
      .reset_n(reset_n),

      .read_req((mem_req & ~mem_write) | fe_req),
      .read_addr(read_addr),
      .read_data(read_data),

      .write_req(mem_req & mem_write),
      .write_addr(mem_addr[15:2]),
      .write_byte_en(byte_en),
      .write_data(mem_data_in)
      );

    reg mem_req_r;
    reg fe_req_r;
    reg [1:0] mem_offset_r;
    reg mem_extend_r;
    reg [1:0] mem_width_r;
    always @(posedge clk)
      if(~reset_n)
        begin
            mem_req_r <= 0;
            fe_req_r <= 0;
        end
      else
        begin
            mem_req_r <= mem_req;
            fe_req_r <= fe_req;
            mem_offset_r <= mem_addr[1:0];
            mem_extend_r <= mem_extend;
            mem_width_r <= mem_width;
        end

    reg [31:0] read_data_ext;
    always @(*)
      casez(mem_width_r)
        2'b00:
          begin
              read_data_ext[7:0] = read_data[mem_offset_r*8+:8];
              read_data_ext[31:8] = mem_extend_r ? {24{read_data_ext[7]}} : 24'b0;
          end
        2'b01:
          begin
              read_data_ext[15:0] = mem_offset_r[1] ? read_data[31:16] : read_data[15:0];
              read_data_ext[31:16] = mem_extend_r ? {16{read_data_ext[15]}} : 16'b0;
          end
        2'b1?:
          read_data_ext = read_data;
      endcase

    reg [31:0] mem_data_out_r;
    reg [31:0] fe_data_r;
    always @(posedge clk)
      if(~reset_n)
        begin
            mem_data_out_r <= 32'b0;
            fe_data_r <= 32'b0;
        end
      else
        begin
            if(mem_req_r)
              mem_data_out_r <= read_data_ext;
            if(fe_req_r)
              fe_data_r <= read_data;
        end

    assign mem_data_out = mem_req_r ? read_data_ext : mem_data_out_r;
    assign fe_data = fe_req_r ? read_data : fe_data_r;

endmodule
