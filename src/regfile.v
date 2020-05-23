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

  input [4:0]       wreg0,
  input [31:0]      wdata0,
  input             wen0,

  input [4:0]       wreg1,
  input [31:0]      wdata1,
  input             wen1
  );

    `include "defines.vh"

    reg [31:0] regs[31:1];
    reg [31:1] valid;

    // read port 1 (with passthrough)
    wire wr0_rs1 = wen0 & (wreg0 == rs1);
    wire wr1_rs1 = wen1 & (wreg1 == rs1);
    always @(*)
      begin
          if(~|rs1)
            begin
                rs1_valid = 1;
                rs1_data = 32'b0;
            end
          else if(wr0_rs1)
            begin
                rs1_valid = 1;
                rs1_data = wdata0;
            end
          else if(wr1_rs1)
            begin
                rs1_valid = 1;
                rs1_data = wdata1;
            end
          else
            begin
                rs1_valid = valid[rs1];
                rs1_data = regs[rs1];
            end
      end

    // read port 2 (with passthrough)
    wire wr0_rs2 = wen0 & (wreg0 == rs2);
    wire wr1_rs2 = wen1 & (wreg1 == rs2);
    always @(*)
      begin
          if(~|rs2)
            begin
                rs2_valid = 1;
                rs2_data = 32'b0;
            end
          else if(wr0_rs2)
            begin
                rs2_valid = 1;
                rs2_data = wdata0;
            end
          else if(wr1_rs2)
            begin
                rs2_valid = 1;
                rs2_data = wdata1;
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
          if(wen1 && |wreg1)
            $display("%d: regfile: port 1 write %0s (x%0d) = %08x", $stime, abi_name(wreg1), wreg1, wdata1);
          if(wen0 && |wreg0)
            begin
                write_time = $stime;
                write_reg = wreg0;
                write_val = wdata0;
                #1 $display("%d: regfile: port 0 write %0s (x%0d) = %08x", write_time, abi_name(write_reg), write_reg, write_val);
            end
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
            if(wen1 && |wreg1)
              begin
                  regs[wreg1] <= wdata1;
                  valid[wreg1] <= 1;
              end
            if(wen0 && |wreg0)
              begin
                  regs[wreg0] <= wdata0;
                  valid[wreg0] <= 1;
              end
            if(reserve && |rd)
              valid[rd] <= 0;
        end

endmodule
