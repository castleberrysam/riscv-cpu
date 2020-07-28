`timescale 1ns/1ps

module pma_checker(
  input logic         clk_core,
  input logic         reset_n,

  input logic         read,
  input logic         write,
  input logic [1:0]   width,
  input logic [28:12] ppn,

  output logic        pma_cacheable,
  output logic        pma_error
  );

  // address space:
  // 00000000-0000ffff: 64KiB block rom
  // 01000000-01ffffff: 16MiB QSPI flash
  // 02000000-0200ffff: mmio peripherals
  // 10000000-1fffffff: 256MiB DDR3 dram
  // accessing any other address raises an error (access fault)
  always_ff @(posedge clk_core)
    unique casez(ppn[28:16])
      'h0000: begin
        pma_cacheable <= 1;
        pma_error <= write;
      end
      'h01??: begin
        pma_cacheable <= 1;
        pma_error <= write;
      end
      'h0200: begin
        pma_cacheable <= 0;
        pma_error <= write | ~width[1];
      end
      'h1???: begin
        pma_cacheable <= 1;
        pma_error <= 0;
      end
      default: begin
        pma_cacheable <= 0;
        pma_error <= 1;
      end
    endcase

endmodule
