`timescale 1ns/1ps
`default_nettype none

module regfile(
  input         clk,
  input         reset_n,

  input [4:0]   rs1,
  output        rs1_valid,
  output [31:0] rs1_data,

  input [4:0]   rs2,
  output        rs2_valid,
  output [31:0] rs2_data,

  input [4:0]   rd,
  input         reserve,

  input [4:0]   wreg0,
  input [31:0]  wdata0,
  input         wen0,

  input [4:0]   wreg1,
  input [31:0]  wdata1,
  input         wen1
  );

    function [39:0] abi_name(
      input [4:0] regnum
      );
        case(regnum)
          5'd0: abi_name = "zero";
          5'd1: abi_name = "ra";
          5'd2: abi_name = "sp";
          5'd3: abi_name = "gp";
          5'd4: abi_name = "tp";
          5'd5: abi_name = "t0";
          5'd6: abi_name = "t1";
          5'd7: abi_name = "t2";
          5'd8: abi_name = "fp";
          5'd9: abi_name = "s1";
          5'd10: abi_name = "a0";
          5'd11: abi_name = "a1";
          5'd12: abi_name = "a2";
          5'd13: abi_name = "a3";
          5'd14: abi_name = "a4";
          5'd15: abi_name = "a5";
          5'd16: abi_name = "a6";
          5'd17: abi_name = "a7";
          5'd18: abi_name = "s2";
          5'd19: abi_name = "s3";
          5'd20: abi_name = "s4";
          5'd21: abi_name = "s5";
          5'd22: abi_name = "s6";
          5'd23: abi_name = "s7";
          5'd24: abi_name = "s8";
          5'd25: abi_name = "s9";
          5'd26: abi_name = "s10";
          5'd27: abi_name = "s11";
          5'd28: abi_name = "t3";
          5'd29: abi_name = "t4";
          5'd30: abi_name = "t5";
          5'd31: abi_name = "t6";
        endcase
    endfunction

    reg [31:0]  regs[31:1];
    reg [31:1] valid;

    assign rs1_data = rs1 ? regs[rs1] : 32'b0;
    assign rs1_valid = rs1 ? valid[rs1] : 1;
    
    assign rs2_data = rs2 ? regs[rs2] : 32'b0;
    assign rs2_valid = rs2 ? valid[rs2] : 1;

    integer i;
    reg [31:0] write_time;
    always @(posedge clk)
      if(~reset_n)
        begin
            for(i=1;i<32;i=i+1)
              begin
                  regs[i] <= 32'b0;
                  valid[i] <= 1;
              end
        end
      else
        begin
            if(|rd & reserve)
              begin
                  //$display("%d: regfile: reserve %0s (x%0d)", $stime, abi_name(rd), rd);
                  valid[rd] <= 0;
              end
            if(wen1 && |wreg1)
              begin
                  $display("%d: regfile: port 1 write %0s (x%0d) = %08x", $stime, abi_name(wreg1), wreg1, wdata1);
                  regs[wreg1] <= wdata1;
                  valid[wreg1] <= 1;
              end
            if(wen0 && |wreg0)
              begin
                  regs[wreg0] <= wdata0;
                  valid[wreg0] <= 1;

                  write_time = $stime;
                  #1 $display("%d: regfile: port 0 write %0s (x%0d) = %08x", write_time, abi_name(wreg0), wreg0, wdata0);
              end
        end

endmodule
