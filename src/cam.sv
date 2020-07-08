`timescale 1ns/1ps

module cam(
  input logic          clk,
  input logic          reset_n,

  // read port
  // read_tag_in is delayed by one cycle
  input logic          read_req,
  input logic [11:2]   read_index,
  input logic [28:12]  read_tag_in,

  output logic         read_hit,

  output logic [28:12] read_tag_out,
  output logic [31:0]  read_data,
  output logic [1:0]   read_flags,

  // write port
  input logic [11:2]   write_index,

  input logic          write_req_data,
  input logic [31:0]   write_data,
  input logic [3:0]    write_mask,

  input logic          write_req_tag_flags,
  input logic [28:12]  write_tag,
  input logic [1:0]    write_flags
  );

  logic [1:0] read_way;

  logic        read_req_r;
  always_ff @(posedge clk)
    read_req_r <= read_req;

  // silly hack needed since the vivado block ram inference is... less than ideal
  logic [7:0]  data_mem_wen;
  logic [63:0] data_mem_wdata;
  assign data_mem_wen = {write_mask & {4{read_way[0]}}, write_mask & {4{read_way[1]}}};
  assign data_mem_wdata = {write_data,write_data};

  // data store
  logic [31:0] rdata[2];
  logic [63:0] data_mem[0:1023];
  always_ff @(posedge clk) begin
    if(read_req)
      {rdata[0],rdata[1]} <= data_mem[read_index];
    if(write_req_data)
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
  assign ways[0] = tag_mem_rdata[23:0];
  assign ways[1] = tag_mem_rdata[47:24];

  logic [47:0] tag_mem[0:255];
  always_ff @(posedge clk) begin
    if(read_req)
      tag_mem_rdata <= tag_mem[read_index[11:4]];
    if(write_req_tag_flags)
      for(int i=0;i<2;i++)
        if(read_way[i])
          tag_mem[write_index[11:4]][i*24+:24] <= {write_tag,write_flags,5'b0};
  end

  logic lru;
  logic lru_mem[0:255];
  always_ff @(posedge clk) begin
    if(read_req)
      lru <= lru_mem[read_index[11:4]];
    if(read_req_r & read_hit)
      lru_mem[write_index[11:4]] <= read_way[0];
  end

  logic [1:0] hits;
  always_comb begin
    // flag 0 is used as the valid bit
    for(int i=0;i<2;i++)
      hits[i] = ways[i].flags[0] & (ways[i].tag == read_tag_in);

    // on a miss, output the lru line for quicker eviction
    read_hit = |hits;
    read_way = read_hit ? hits : (1 << lru);

    read_data = '0;
    read_tag_out = '0;
    read_flags = '0;
    for(int i=0;i<2;i++)
      if(read_way[i]) begin
        read_data |= rdata[i];
        read_tag_out |= ways[i].tag;
        read_flags |= ways[i].flags;
      end
  end

endmodule
