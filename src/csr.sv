`timescale 1ns/1ps

module csr(
  input logic         clk,
  input logic         reset_n,

  // generic read/write interface
  input logic [11:0]  addr,
  input logic [1:0]   write,
  input logic [31:0]  data_in,
  output logic        error,
  output logic [31:0] data_out,

  // exception interface
  input logic         wb_valid,
  input logic         wb_exc,
  input ecause_t      wb_exc_cause,
  input logic [31:2]  wb_pc,
  input logic [31:0]  wb_data,
  output logic        csr_setpc,
  output logic [31:2] csr_newpc
  );

  logic        wen;
  logic [31:0] wdata;
  always_comb begin
    wen = 1;
    unique0 case(write)
      'b00: wen = 0;
      'b01: wdata = data_in;
      'b10: wdata = data_out | data_in;
      'b11: wdata = data_out & ~data_in;
    endcase
  end

  logic [63:0] cycle;
  always_ff @(posedge clk)
    if(~reset_n)
      cycle <= 0;
    else
      cycle <= cycle + 1;

  logic [63:0] instret;
  always_ff @(posedge clk)
    if(~reset_n)
      instret <= 0;
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
  always_ff @(posedge clk)
    if(~reset_n)
      mstatus <= 32'b11 << 11;
    else if(wen && addr == 'h300) begin
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
  always_ff @(posedge clk)
    if(~reset_n)
      mtvec <= 0;
    else if(wen && addr == 'h305) begin
      mtvec[0] <= wdata[0];
      // mtvec[6:2] will be ignored for interrupts in vectored mode
      mtvec[31:2] <= wdata[31:2];
    end

  logic [31:0] mscratch;
  always_ff @(posedge clk)
    if(~reset_n)
      mscratch <= 0;
    else if(wen && addr == 'h340)
      mscratch <= wdata;

  logic [31:2] mepc;
  always_ff @(posedge clk)
    if(~reset_n)
      mepc <= 0;
    else if(wen && addr == 'h341)
      mepc <= wdata[31:2];
    else if(wb_exc & ~eret)
      mepc <= wb_pc;

  logic [31:0] mcause;
  always_ff @(posedge clk)
    if(~reset_n)
      mcause <= 0;
    else if(wen && addr == 'h342) begin
      mcause <= 0;
      mcause[31] <= wdata[31];
      // interrupt cause is 5 bits, exception cause is 4 bits
      if(wdata[31])
        mcause[4:0] <= wdata[4:0];
      else
        mcause[3:0] <= wdata[3:0];
    end else if(wb_exc & ~eret) begin
      mcause <= 0;
      mcause[3:0] <= wb_exc_cause;
    end

  logic [31:0] exc_tval;
  always_comb
    unique case(wb_exc_cause)
      IALIGN, IFAULT, IPFAULT: exc_tval = wb_pc;
      IILLEGAL: exc_tval = wb_data;

      LALIGN, LFAULT, LPFAULT: exc_tval = wb_data;
      SALIGN, SFAULT, SPFAULT: exc_tval = wb_data;

      UCALL, SCALL, MCALL: exc_tval = 0;
      EBREAK: exc_tval = wb_pc;

      default: exc_tval = 0;
    endcase

  logic [31:0] mtval;
  always_ff @(posedge clk)
    if(~reset_n)
      mtval <= 0;
    else if(wen && addr == 'h343)
      mtval <= wdata;
    else if(wb_exc & ~eret)
      mtval <= exc_tval;

  always_comb begin
    csr_setpc = wb_exc;
    csr_newpc = ~eret ? mtvec[31:2] : mepc;
  end

  // read port
  logic unimp;
  always_comb begin
    unimp = 0;
    unique case(addr)
      'h300: data_out = mstatus;
      'h305: data_out = mtvec;
      'h340: data_out = mscratch;
      'h341: data_out = {mepc,2'b0};
      'h342: data_out = mcause;
      'h343: data_out = mtval;

      'hc00: data_out = cycle[31:0];
      'hc01: data_out = cycle[31:0];
      'hc02: data_out = instret[31:0];
      'hc80: data_out = cycle[63:32];
      'hc81: data_out = cycle[63:32];
      'hc82: data_out = instret[63:32];
      default: begin
        unimp = 1;
        data_out = 0;
      end
    endcase
  end

  assign error = unimp | (wen & addr[11] & addr[10]);

endmodule
