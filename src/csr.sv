`timescale 1ns/1ps

module csr(
  input logic         clk,
  input logic         reset_n,

  input logic         inc_instret,

  input logic [11:0]  addr,
  input logic [1:0]   write,
  input logic [31:0]  data_in,

  output logic [31:0] data_out
  );

  logic        wen;
  logic [31:0] wdata;
  always_comb begin
    wen = 1;
    case(write)
      2'b00: wen = 0;
      2'b01: wdata = data_in;
      2'b10: wdata = data_out | data_in;
      2'b11: wdata = data_out & ~data_in;
    endcase
  end

  logic [63:0] cycle;
  always_ff @(posedge clk)
    if(~reset_n)
      cycle <= 64'b0;
    else if(wen && (addr == 12'hc00 || addr == 12'hc01))
      cycle[31:0] <= wdata;
    else if(wen && (addr == 12'hc80 || addr == 12'hc81))
      cycle[63:32] <= wdata;
    else
      cycle <= cycle + 1;

  logic [63:0] instret;
  always_ff @(posedge clk)
    if(~reset_n)
      instret <= 64'b0;
    else if(wen && addr == 12'hc02)
      instret[31:0] <= wdata;
    else if(wen && addr == 12'hc82)
      instret[63:32] <= wdata;
    else if(inc_instret)
      instret <= instret + 1;

  // read port
  always_comb
    case(addr)
      12'hc00: data_out = cycle[31:0];
      12'hc01: data_out = cycle[31:0];
      12'hc02: data_out = instret[31:0];
      12'hc80: data_out = cycle[63:32];
      12'hc81: data_out = cycle[63:32];
      12'hc82: data_out = instret[63:32];
      default: data_out = 32'b0;
    endcase

endmodule
