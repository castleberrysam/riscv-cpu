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


  int branches, misses;
  always_ff @(negedge clk_core)
    if(uut.execute.ex_valid) begin
      if(uut.execute.ex_br)
        branches++;
      if(uut.execute.ex_br_miss)
        misses++;
    end

  int bus_cycles, bus_reads, bus_writes;
  always_ff @(posedge clk_core) begin
    if(uut.bus_main.cmd_valid)
      bus_cycles++;
    if(uut.bus_main.cmd_beat_in) begin
      if(uut.bus_main.cmd_in)
        bus_reads++;
      else
        bus_writes++;
    end
  end

  bit fe0_read_req_r;
  int icam_hits, icam_misses;
  always_ff @(posedge clk_core) begin
    fe0_read_req_r <= uut.icache.fe0_read_req;
    if(fe0_read_req_r) begin
      if(uut.icache.ic_cam_read_hit)
        icam_hits++;
      else
        icam_misses++;
    end
  end

  bit mem0_dc_read_r;
  int dcam_hits, dcam_misses;
  always_ff @(posedge clk_core) begin
    mem0_dc_read_r <= uut.dcache.mem0_dc_read;
    if(mem0_dc_read_r) begin
      if(uut.dcache.dc_cam_read_hit)
        dcam_hits++;
      else
        dcam_misses++;
    end
  end

  initial
    begin
      // $dumpfile("tb_top.vcd");
      // $dumpvars;

      clk_core = 0;
      clk_mig_ref = 0;
      reset_n = 0;
      #100;
      reset_n = 1;

      @(posedge uut.write.test_stop);
      #1;

      $display("Test complete");
      $display("Cycles elapsed: %0d", uut.csr.cycle);
      $display("Instructions retired: %0d", uut.csr.instret);
      $display("Average CPI: %.3f", $itor(uut.csr.cycle) / $itor(uut.csr.instret));
      $display("Branch predictor accuracy: %.3f", 1.0 - ($itor(misses) / $itor(branches)));
      $display("Bus utilization: %.3f", $itor(bus_cycles) / $itor(uut.csr.cycle));
      $display("Bus write percentage: %.3f", $itor(bus_writes) / $itor(bus_reads + bus_writes));
      $display("I$ hit rate: %.3f", $itor(icam_hits) / $itor(icam_hits + icam_misses));
      $display("D$ hit rate: %.3f", $itor(dcam_hits) / $itor(dcam_hits + dcam_misses));
      $finish;
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
