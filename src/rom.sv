`timescale 1ns/1ps

module rom(
  input logic         clk_core,
  input logic         reset_n,

  input logic         bmain_cvalid_rom,
  output logic        rom_cready,
  input logic         bmain_cmd,
  input logic [27:2]  bmain_addr,

  output logic        rom_rvalid,
  input logic         bmain_rready_rom,
  output logic        rom_rlast,
  output logic [31:0] rom_rdata,

  output logic        rom_error,
  input logic         bmain_eack_rom
  );

  assign rom_error = 0;

  logic        cmd_valid;
  logic        rlast;
  logic [1:0]  offset;
  logic [15:4] addr;
  always_ff @(posedge clk_core)
    if(~reset_n)
      cmd_valid <= 0;
    else if(bmain_cvalid_rom & rom_cready) begin
      cmd_valid <= 1;
      offset <= 'd0;
      addr <= bmain_addr[15:4];
    end else if((offset == 'd0) | bmain_rready_rom) begin
      if(rlast)
        cmd_valid <= 0;
      offset <= offset + 'd1;
    end

  assign rlast = offset == 'd3;
  assign rom_cready = ~cmd_valid | rlast;

  always_ff @(posedge clk_core) begin
    rom_rvalid <= cmd_valid;
    rom_rlast <= rlast;
  end

  (* rom_style = "block" *)
  logic [31:0] storage[0:16383];

`ifdef SYNTHESIS
`ifdef XILINX
  initial
    $readmemb("rom.mif", storage);
`endif
`else
  string memfile;
  int fd;
  initial begin
    for(int i=0;i<16384;i++)
      storage[i] = 0;

    if(!$value$plusargs("memfile=%s", memfile))
      memfile = "memory.hex";

    fd = $fopen(memfile, "r");
    if(!fd) begin
      $display(STDERR, "Cannot open memfile %0s", memfile);
      $finish;
    end
    $fclose(fd);

    $readmemh(memfile, storage);
  end  
`endif

  logic [15:2] index;
  assign index = {addr,offset};

  always_ff @(posedge clk_core)
    if(cmd_valid)
      rom_rdata <= storage[index];

endmodule
