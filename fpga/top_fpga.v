`timescale 1ns/1ps
`default_nettype none

module top_fpga(
  input wire        CLK100MHZ,
  input wire [3:0]  btn,
  output wire [3:0] led
  );

    wire locked;
    wire clkfb;
    wire clk80mhz;
    PLLE2_BASE #(
      .CLKIN1_PERIOD(10.000),
      .STARTUP_WAIT("TRUE"),

      // resulting base clock needs to be 800-1600MHz
      .CLKFBOUT_MULT(8),
      .DIVCLK_DIVIDE(1),

      .CLKOUT0_DIVIDE(10),
      .CLKOUT1_DIVIDE(),
      .CLKOUT2_DIVIDE(),
      .CLKOUT3_DIVIDE(),
      .CLKOUT4_DIVIDE(),
      .CLKOUT5_DIVIDE()
      ) pll(
      .CLKIN1(CLK100MHZ),
      .RST(0),

      .LOCKED(locked),
      .PWRDWN(0),

      .CLKFBIN(clkfb),
      .CLKFBOUT(clkfb),

      .CLKOUT0(clk80mhz),
      .CLKOUT1(),
      .CLKOUT2(),
      .CLKOUT3(),
      .CLKOUT4(),
      .CLKOUT5()
      );

    top top(
      .clk(clk80mhz),
      .reset_n(~btn[0] & locked)
      );

    assign led = top.decode.regfile.regs[8][3:0];

endmodule
