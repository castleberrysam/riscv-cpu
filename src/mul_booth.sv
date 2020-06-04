`timescale 1ns/1ps

module mul_booth(
  input logic         clk,
  input logic         reset_n,

  input logic         go,
  input logic         sign0,
  input logic         sign1,
  input logic [31:0]  m,
  input logic [31:0]  r,

  output logic        done,
  output logic [63:0] result
  );

  logic [33:0] state;
  logic [64:0] acc;

  assign done = go & state[33];
  assign result = acc[64:1];

  always_ff @(posedge clk)
    if(~reset_n)
      state <= 34'b1;
    else if(go)
      state <= {state[32:0],state[33]};

  logic [32:0] sum;
  always_comb begin
    sum = {1'b0,acc[64:33]};
    unique0 case({sign0,acc[1:0]})
      'b010: sum = sum + m;
      'b011: sum = sum + m;

      'b101: sum = sum + m;
      'b110: sum = sum - m;
    endcase
  end

  logic msb;
  assign msb = sign1 ? sum[31] : sum[32];
  always_ff @(posedge clk)
    if(state[0])
      acc <= {32'b0,r,1'b0};
    else
      acc <= {msb,sum[31:0],acc[32:1]};

endmodule
