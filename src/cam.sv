`timescale 1ns/1ps

module cam(
  input logic          clk,
  input logic          reset_n,

  // read port
  // read_tag is delayed by one cycle
  input logic          read_req,
  input logic [11:2]   read_index,
  input logic [28:12]  read_tag,

  output logic         read_hit,
  output logic [31:0]  read_data,

  // write port
  input logic          write_req,
  input logic          write_lru_way,
  input logic [3:2]    write_offset,

  input logic [31:0]   write_data,
  input logic [3:0]    write_mask,

  input logic [28:12]  write_tag,
  input logic [1:0]    write_flags,

  // lru_update is delayed by one cycle
  input logic          lru_update,
  output logic [28:12] lru_tag,
  output logic [1:0]   lru_flags
  );

  parameter PARENT = "";

  logic [11:4] read_set;
  logic [3:2]  read_offset;
  assign read_set = read_index[11:4];
  assign read_offset = read_index[3:2];

  logic [1:0] lru_way, write_way;
  assign lru_way = 2'b1 << lru;
  assign write_way = write_lru_way ? lru_way : hits;

  logic [11:2] write_index;
  assign write_index = {write_set,write_offset};

  // write forwarding
  logic [31:0]  write_data_r;
  logic [28:12] write_tag_r;
  logic [1:0]   write_flags_r;
  always_ff @(posedge clk) begin
    write_data_r <= write_data;
    write_tag_r <= write_tag;
    write_flags_r <= write_flags;
  end

  logic [3:0] fwd_data_sel;
  logic [1:0] fwd_tag_flags_sel;
  always_ff @(posedge clk) begin
    fwd_data_sel <= '0;
    fwd_tag_flags_sel <= '0;
    if(read_req & write_req & (read_set == write_set)) begin
      if(read_offset == write_offset)
        fwd_data_sel <= write_mask;
      fwd_tag_flags_sel <= write_way;
    end
  end

  logic        read_req_r;
  logic [11:4] write_set;
  always_ff @(posedge clk) begin
    read_req_r <= read_req;
    if(read_req)
      write_set <= read_set;
  end

  // silly hack needed since the vivado block ram inference is... less than ideal
  logic [7:0]  data_mem_wen;
  logic [63:0] data_mem_wdata;
  assign data_mem_wen = {write_mask & {4{write_way[1]}}, write_mask & {4{write_way[0]}}};
  assign data_mem_wdata = {write_data,write_data};

  // data store
  logic [31:0] rdata[2];

  logic [63:0] data_mem_rdata;
  always_comb
    for(int i=0;i<2;i++)
      for(int j=0;j<4;j++)
        rdata[i][j*8+:8] = fwd_data_sel[j] ? write_data_r[j*8+:8] : data_mem_rdata[(i*32)+(j*8)+:8];

  logic [63:0] data_mem[0:1023];
  always_ff @(posedge clk) begin
    if(read_req)
      data_mem_rdata <= data_mem[read_index];
    if(write_req)
      for(int i=0;i<8;i++)
        if(data_mem_wen[i])
          data_mem[write_index][i*8+:8] <= data_mem_wdata[i*8+:8];
  end

  // tag+flag store
  struct packed {
    // size needs to be a multiple of 8 for partial write
    logic [28:12] tag;
    logic [1:0]   flags;
    logic [4:0]   dummy;
  } ways[2];

  logic [47:0] tag_mem_rdata;
  always_comb
    for(int i=0;i<2;i++)
      ways[i] = fwd_tag_flags_sel[i] ? {write_tag_r,write_flags_r,5'b0} : tag_mem_rdata[i*24+:24];

  logic [47:0] tag_mem[0:255];
  always_ff @(posedge clk) begin
    if(read_req)
      tag_mem_rdata <= tag_mem[read_set];
    if(write_req)
      for(int i=0;i<2;i++)
        if(write_way[i])
          tag_mem[write_set][i*24+:24] <= {write_tag,write_flags,5'b0};
  end

  logic lru;
  logic lru_mem[0:255];
  always_ff @(posedge clk) begin
    if(read_req)
      lru <= lru_mem[read_set];
    if(lru_update & ((read_req_r & read_hit) | write_req))
      lru_mem[write_set] <= write_way[0];
  end

  logic [1:0] hits;
  always_comb begin
    // flag 0 is used as the valid bit
    for(int i=0;i<2;i++)
      hits[i] = ways[i].flags[0] & (ways[i].tag == read_tag);
    read_hit = |hits;

    read_data = '0;
    for(int i=0;i<2;i++)
      if(hits[i])
        read_data |= rdata[i];

    lru_tag = '0;
    lru_flags = '0;
    for(int i=0;i<2;i++)
      if(lru_way[i]) begin
        lru_tag |= ways[i].tag;
        lru_flags |= ways[i].flags;
      end
  end

  // TODO will not work for synthesis
  initial begin
    for(int i=0;i<256;i++) begin
      tag_mem[i] = '0;
      lru_mem[i] = 0;
    end
  end

`ifndef SYNTHESIS
  always_ff @(negedge clk) begin
    if(write_req)
      $display("%d: %s cam: write at %b way %b = data %x mask %b tag %b flags %b", $stime, PARENT, write_index, write_way, write_data, write_mask, write_tag, write_flags);
  end
`endif

endmodule
