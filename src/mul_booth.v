`timescale 1ns/1ps
`default_nettype none

module mul_booth(
  input         clk,
  input         reset_n,

  input         go,
  input         sign0,
  input         sign1,
  input [31:0]  m,
  input [31:0]  r,

  output        done,
  output [63:0] result
  );

    reg [33:0] state;
    reg [64:0] acc;

    assign done = go & state[33];
    assign result = acc[64:1];

    always @(posedge clk)
      if(~reset_n)
        state <= 34'b1;
      else if(go)
        state <= {state[32:0],state[33]};

    reg [32:0] sum;
    always @(*)
      begin
          sum = {1'b0,acc[64:33]};
          case({sign0,acc[1:0]})
            3'b010: sum = sum + m;
            3'b011: sum = sum + m;

            3'b101: sum = sum + m;
            3'b110: sum = sum - m;
          endcase
      end

    wire msb = sign1 ? sum[31] : sum[32];
    always @(posedge clk)
      if(~reset_n)
        ;
      else if(state[0])
        acc <= {32'b0,r,1'b0};
      else
        acc <= {msb,sum[31:0],acc[32:1]};

endmodule
