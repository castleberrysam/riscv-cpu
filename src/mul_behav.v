`timescale 1ns/1ps
`default_nettype none

module mul_behav(
  input wire         clk,
  input wire         reset_n,

  input wire         go,
  input wire         sign0,
  input wire         sign1,
  input wire [31:0]  m,
  input wire [31:0]  r,

  output wire        done,
  output wire [63:0] result
  );

    parameter LATENCY = 4;

    reg [63:0] mul_result;
    always @(*)
      casez({sign0,sign1})
        2'b00: mul_result = m * r;
        2'b01: mul_result = $signed(m) * $signed({1'b0,r});
        2'b1?: mul_result = $signed(m) * $signed(r);
      endcase

    generate
        if(LATENCY < 1)
          begin
              assign done = go;
              assign result = mul_result;
          end
        else
          begin
              reg [LATENCY:0] state;

              always @(posedge clk)
                if(~reset_n)
                  state <= 1;
                else if(go)
                  state <= {state[LATENCY-1:0],state[LATENCY]};

              reg [63:0] pipe[LATENCY-1:0];

              integer i;
              always @(posedge clk)
                begin
                    pipe[0] <= mul_result;
                    for(i=1;i<LATENCY;i=i+1)
                      pipe[i] <= pipe[i-1];
                end

              assign done = state[LATENCY];
              assign result = pipe[LATENCY-1];
          end
    endgenerate

endmodule
