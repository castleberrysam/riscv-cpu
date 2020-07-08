`timescale 1ns/1ps

module top_fpga(
  input logic         sys_clk_i,
  input logic         clk_12mhz,
  
  output logic [13:0] ddr3_addr,
  output logic [2:0]  ddr3_ba,
  output logic        ddr3_ras_n,
  output logic        ddr3_cas_n,
  output logic        ddr3_we_n,
  output logic        ddr3_reset_n,
  output logic        ddr3_ck_p,
  output logic        ddr3_ck_n,
  output logic        ddr3_cke,
  output logic        ddr3_cs_n,
  output logic [1:0]  ddr3_dm,
  output logic        ddr3_odt,
  inout logic [15:0]  ddr3_dq,
  inout logic [1:0]   ddr3_dqs_p,
  inout logic [1:0]   ddr3_dqs_n  
  );

  logic clk_core, clk_mig_sys, clk_mig_ref;
  assign clk_mig_sys = sys_clk_i;

  logic locked;
  MMCME2_BASE #(
    .CLKIN1_PERIOD(83.333),
    .STARTUP_WAIT("TRUE"),

    // resulting base clock needs to be 600-1200MHz
    .CLKFBOUT_MULT_F(50.000), // 600MHz
    .DIVCLK_DIVIDE(1),

    .CLKOUT0_DIVIDE_F(6.000), // 100MHz
    .CLKOUT1_DIVIDE(3), // 200MHz
    .CLKOUT2_DIVIDE(),
    .CLKOUT3_DIVIDE(),
    .CLKOUT4_DIVIDE(),
    .CLKOUT5_DIVIDE(),
    .CLKOUT6_DIVIDE()
    ) mmcm(
    .CLKIN1(clk_12mhz),
    .RST(0),

    .LOCKED(locked),
    .PWRDWN(0),

    .CLKFBOUT(clk_fb),
    .CLKFBOUTB(),
    .CLKFBIN(clk_fb),

    .CLKOUT0(clk_core),
    .CLKOUT0B(),
    .CLKOUT1(clk_mig_ref),
    .CLKOUT1B(),
    .CLKOUT2(),
    .CLKOUT2B(),
    .CLKOUT3(),
    .CLKOUT3B(),
    .CLKOUT4(),
    .CLKOUT5(),
    .CLKOUT6()
    );

  logic reset_n;
  assign reset_n = locked;

  top top
    (/*AUTOINST*/
    // Outputs
    .ddr3_addr       (ddr3_addr[13:0]),
    .ddr3_ba         (ddr3_ba[2:0]),
    .ddr3_ras_n,
    .ddr3_cas_n,
    .ddr3_we_n,
    .ddr3_reset_n,
    .ddr3_ck_p,
    .ddr3_ck_n,
    .ddr3_cke,
    .ddr3_cs_n,
    .ddr3_dm         (ddr3_dm[1:0]),
    .ddr3_odt,
    // Inouts
    .ddr3_dq         (ddr3_dq[15:0]),
    .ddr3_dqs_p      (ddr3_dqs_p[1:0]),
    .ddr3_dqs_n      (ddr3_dqs_n[1:0]),
    // Inputs
    .clk_core,
    .clk_mig_sys,
    .clk_mig_ref,
    .reset_n);

endmodule
