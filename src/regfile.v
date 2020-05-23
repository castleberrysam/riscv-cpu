`timescale 1ns/1ps
`default_nettype none

module regfile(
  input             clk,
  input             reset_n,

  input [4:0]       rs1,
  output reg        rs1_valid,
  output reg [31:0] rs1_data,

  input [4:0]       rs2,
  output reg        rs2_valid,
  output reg [31:0] rs2_data,

  input [4:0]       rd,
  input             reserve,

  input [4:0]       wreg,
  input [31:0]      wdata,
  input             wen

  );

    `include "defines.vh"

    reg [31:0] regs[31:1];
    reg [31:1] valid;

    // read port 1 (with passthrough)
    wire wr_rs1 = wen & (wreg == rs1);
    always @(*)
      begin
          if(~|rs1)
            begin
                rs1_valid = 1;
                rs1_data = 32'b0;
            end
          else if(wr_rs1)
            begin
                rs1_valid = 1;
                rs1_data = wdata;
            end
          else
            begin
                rs1_valid = valid[rs1];
                rs1_data = regs[rs1];
            end
      end

    // read port 2 (with passthrough)
    wire wr_rs2 = wen & (wreg == rs2);
    always @(*)
      begin
          if(~|rs2)
            begin
                rs2_valid = 1;
                rs2_data = 32'b0;
            end
          else if(wr_rs2)
            begin
                rs2_valid = 1;
                rs2_data = wdata;
            end
          else
            begin
                rs2_valid = valid[rs2];
                rs2_data = regs[rs2];
            end
      end

`ifndef SYNTHESIS
    reg [31:0] write_time;
    reg [4:0]  write_reg;
    reg [31:0] write_val;
    always @(posedge clk)
      begin
          if(reserve && |rd)
            $display("%d: regfile: reserve %0s (x%0d)", $stime, abi_name(rd), rd);
          if(wen && |wreg)
            $display("%d: regfile: write %0s (x%0d) = %08x", $stime, abi_name(wreg), wreg, wdata);
      end
`endif

    integer i;
    always @(posedge clk)
      if(~reset_n)
        for(i=1;i<32;i=i+1)
          begin
              regs[i] <= 32'b0;
              valid[i] <= 1;
          end
      else
        begin
            if(wen && |wreg)
              begin
                  regs[wreg] <= wdata;
                  valid[wreg] <= 1;
              end
            if(reserve && |rd)
              valid[rd] <= 0;
        end

endmodule
