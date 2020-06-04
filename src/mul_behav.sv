`timescale 1ns/1ps

module mul_behav(
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

  parameter LATENCY = 4;

  logic [63:0] mul_result;
  always_comb
    unique0 casez({sign0,sign1})
      2'b00: mul_result = m * r;
      2'b01: mul_result = $signed(m) * $signed({1'b0,r});
      2'b1?: mul_result = $signed(m) * $signed(r);
     endcase

  generate
    if(LATENCY < 1) begin
      assign done = go;
      assign result = mul_result;
    end else begin
      logic [LATENCY:0] state;

      always_ff @(posedge clk)
        if(~reset_n)
          state <= 1;
        else if(go)
          state <= {state[LATENCY-1:0],state[LATENCY]};

      logic [63:0] pipe[LATENCY-1:0];

      always_ff @(posedge clk) begin
        pipe[0] <= mul_result;
        for(int i=1;i<LATENCY;i++)
          pipe[i] <= pipe[i-1];
      end

      assign done = state[LATENCY];
      assign result = pipe[LATENCY-1];
    end
  endgenerate

endmodule
