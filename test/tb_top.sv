`timescale 1ns/1ps

`include "../src/defines.svh"

module tb_top(
  );

  /*AUTOREGINPUT*/
  // Beginning of automatic reg inputs (for undeclared instantiated-module inputs)
  logic                 clk_core;
  logic                 clk_mig_ref;
  logic                 clk_mig_sys;
  logic                 reset_n;
  // End of automatics

  tri [15:0]            ddr3_dq;
  tri [1:0]             ddr3_dqs_n;
  tri [1:0]             ddr3_dqs_p;
  wire [1:0]            ddr3_dm;

  /*AUTOWIRE*/
  // Beginning of automatic wires (for undeclared instantiated-module outputs)
  logic [13:0]          ddr3_addr;
  logic [2:0]           ddr3_ba;
  logic                 ddr3_cas_n;
  logic                 ddr3_ck_n;
  logic                 ddr3_ck_p;
  logic                 ddr3_cke;
  logic                 ddr3_cs_n;
  logic                 ddr3_odt;
  logic                 ddr3_ras_n;
  logic                 ddr3_reset_n;
  logic                 ddr3_we_n;
  // End of automatics

  top uut
    (/*AUTOINST*/
     // Outputs
     .ddr3_addr         (ddr3_addr[13:0]),
     .ddr3_ba           (ddr3_ba[2:0]),
     .ddr3_ras_n,
     .ddr3_cas_n,
     .ddr3_we_n,
     .ddr3_reset_n,
     .ddr3_ck_p,
     .ddr3_ck_n,
     .ddr3_cke,
     .ddr3_cs_n,
     .ddr3_dm           (ddr3_dm[1:0]),
     .ddr3_odt,
     // Inouts
     .ddr3_dq           (ddr3_dq[15:0]),
     .ddr3_dqs_p        (ddr3_dqs_p[1:0]),
     .ddr3_dqs_n        (ddr3_dqs_n[1:0]),
     // Inputs
     .clk_core,
     .clk_mig_sys,
     .clk_mig_ref,
     .reset_n);

  ddr3 dram(
    .rst_n              (ddr3_reset_n),
    .ck                 (ddr3_ck_p),
    .ck_n               (ddr3_ck_n),
    .cke                (ddr3_cke),
    .cs_n               (ddr3_cs_n),
    .ras_n              (ddr3_ras_n),
    .cas_n              (ddr3_cas_n),
    .we_n               (ddr3_we_n),
    .dm_tdqs            (ddr3_dm),
    .ba                 (ddr3_ba),
    .addr               (ddr3_addr),
    .dq                 (ddr3_dq),
    .dqs                (ddr3_dqs_p),
    .dqs_n              (ddr3_dqs_n),
    .tdqs_n             (),
    .odt                (ddr3_odt)
    );

  initial
    begin
      $dumpfile("tb_top.vcd");
      $dumpvars;

      clk_core = 0;
      clk_mig_ref = 0;
      reset_n = 0;
      #100;
      reset_n = 1;

      @(posedge uut.write.test_stop);
      #1 $finish;
    end

  // core clock: 100MHz
  always
    #5 clk_core = ~clk_core;

  // mig system clock: 100MHz
  assign clk_mig_sys = clk_core;
  
  // mig ref clock: 200MHz
  always
    #2.5 clk_mig_ref = ~clk_mig_ref;

endmodule
