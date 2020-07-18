`timescale 1ns/1ps

module csr(
  input logic         clk_core,
  input logic         reset_n,

  // memory1 inputs/outputs
  input logic [11:0]  mem1_csr_addr,
  input logic [1:0]   mem1_csr_write,
  input logic [31:0]  mem1_csr_din,
  output logic        csr_error,
  output logic        csr_flush,
  output logic [31:0] csr_dout,

  // writeback inputs
  input logic         wb_valid,
  input logic         wb_stall,
  input logic         wb_exc,
  input ecause_t      wb_exc_cause,
  input logic         wb_flush,
  input logic [31:2]  wb_pc,

  input logic [31:0]  wb_data,

  // fetch0 outputs
  output logic        csr_kill,
  output logic        csr_fe_inhibit,
  output logic        csr_setpc,
  output logic [31:2] csr_newpc,

  output logic [31:0] csr_satp
  );

  logic        wen;
  logic [31:0] wdata;
  always_comb begin
    wen = 1;
    wdata = '0;
    unique0 case(mem1_csr_write)
      'b00: wen = 0;
      'b01: wdata = mem1_csr_din;
      'b10: wdata = csr_dout | mem1_csr_din;
      'b11: wdata = csr_dout & ~mem1_csr_din;
    endcase
  end

  logic wen_satp;
  assign wen_satp = wen & (mem1_csr_addr == 'h180);

  logic [31:0] satp;
  assign csr_satp = satp;
  always_ff @(posedge clk_core)
    if(~reset_n)
      satp <= '0;
    else if(wen_satp)
      satp <= wdata;

  logic [63:0] cycle;
  always_ff @(posedge clk_core)
    if(~reset_n)
      cycle <= '0;
    else
      cycle <= cycle + 1;

  logic [63:0] instret;
  always_ff @(posedge clk_core)
    if(~reset_n)
      instret <= '0;
    else if(wb_valid)
      instret <= instret + 1;

  logic eret;
  assign eret = wb_exc_cause == ERET;

  // since we currently only have M mode, we only need to implement:
  // MIE (bit 3)
  // MPIE (bit 7)
  // MPP (bits 12:11), hardwired to 11
  // all other bits are hardwired to 0
  logic [31:0] mstatus;
  always_ff @(posedge clk_core)
    if(~reset_n)
      mstatus <= 32'b11 << 11;
    else if(wen && mem1_csr_addr == 'h300) begin
      mstatus[3] <= wdata[3];
      mstatus[7] <= wdata[7];
    end else if(wb_exc)
      if(~eret) begin
        mstatus[3] <= 0;
        mstatus[7] <= mstatus[3];
      end else begin
        mstatus[3] <= mstatus[7];
        mstatus[7] <= 1;
      end

  logic [31:0] mtvec;
  always_ff @(posedge clk_core)
    if(~reset_n)
      mtvec <= '0;
    else if(wen && mem1_csr_addr == 'h305) begin
      mtvec[0] <= wdata[0];
      // mtvec[6:2] will be ignored for interrupts in vectored mode
      mtvec[31:2] <= wdata[31:2];
    end

  logic [31:0] mscratch;
  always_ff @(posedge clk_core)
    if(~reset_n)
      mscratch <= '0;
    else if(wen && mem1_csr_addr == 'h340)
      mscratch <= wdata;

  logic [31:2] mepc;
  always_ff @(posedge clk_core)
    if(~reset_n)
      mepc <= '0;
    else if(wen && mem1_csr_addr == 'h341)
      mepc <= wdata[31:2];
    else if(wb_exc & ~eret)
      mepc <= wb_pc;

  logic [31:0] mcause;
  always_ff @(posedge clk_core)
    if(~reset_n)
      mcause <= '0;
    else if(wen && mem1_csr_addr == 'h342) begin
      mcause <= '0;
      mcause[31] <= wdata[31];
      // interrupt cause is 5 bits, exception cause is 4 bits
      if(wdata[31])
        mcause[4:0] <= wdata[4:0];
      else
        mcause[3:0] <= wdata[3:0];
    end else if(wb_exc & ~eret) begin
      mcause <= '0;
      mcause[3:0] <= wb_exc_cause;
    end

  logic [31:0] exc_tval;
  always_comb
    unique case(wb_exc_cause)
      IALIGN, IFAULT, IPFAULT: exc_tval = wb_pc;
      IILLEGAL: exc_tval = wb_data;

      LALIGN, LFAULT, LPFAULT: exc_tval = wb_data;
      SALIGN, SFAULT, SPFAULT: exc_tval = wb_data;

      UCALL, SCALL, MCALL: exc_tval = '0;
      EBREAK: exc_tval = wb_pc;

      default: exc_tval = '0;
    endcase

  logic [31:0] mtval;
  always_ff @(posedge clk_core)
    if(~reset_n)
      mtval <= '0;
    else if(wen && mem1_csr_addr == 'h343)
      mtval <= wdata;
    else if(wb_exc & ~eret)
      mtval <= exc_tval;

  always_comb begin
    csr_kill = wb_exc | (wb_valid & wb_flush);
    csr_fe_inhibit = wb_stall;
    csr_setpc = wb_exc | wb_stall;
    if(wb_exc)
      csr_newpc = ~eret ? mtvec[31:2] : mepc;
    else
      csr_newpc = wb_pc;
  end

  // read port
  logic unimp;
  always_comb begin
    unimp = 0;
    unique case(mem1_csr_addr)
      'h180: csr_dout = satp;

      'h300: csr_dout = mstatus;
      'h305: csr_dout = mtvec;
      'h340: csr_dout = mscratch;
      'h341: csr_dout = {mepc,2'b0};
      'h342: csr_dout = mcause;
      'h343: csr_dout = mtval;

      'hc00: csr_dout = cycle[31:0];
      'hc01: csr_dout = cycle[31:0];
      'hc02: csr_dout = instret[31:0];
      'hc80: csr_dout = cycle[63:32];
      'hc81: csr_dout = cycle[63:32];
      'hc82: csr_dout = instret[63:32];
      default: begin
        unimp = 1;
        csr_dout = '0;
      end
    endcase
  end

  assign csr_error = unimp | (wen & mem1_csr_addr[11] & mem1_csr_addr[10]);
  assign csr_flush = wen_satp;

`ifndef SYNTHESIS
  always_ff @(negedge clk_core) begin
    if(wen)
      $display("%d: csr: write csr %x = %8x", $stime, mem1_csr_addr, wdata);
    if(wb_exc & ~eret)
      $display("%d: csr: mepc = %8x, mcause = %0d, mtval = %8x", $stime, wb_pc, wb_exc_cause, exc_tval);
  end
`endif

endmodule
