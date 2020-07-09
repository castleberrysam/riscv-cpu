`timescale 1ns/1ps

module tlb(
  input logic          clk,
  input logic          reset_n,

  // read port
  input logic          read_req,
  input logic [8:0]    read_asid,
  input logic [31:12]  read_addr,

  output logic         read_hit,
  output logic         read_super,

  output logic [28:12] read_ppn,
  output logic [7:0]   read_flags,

  // write port
  input logic          write_req,
  input logic          write_super,

  input logic [31:21]  write_tag,
  input logic [8:0]    write_asid,
  input logic [28:12]  write_ppn,
  input logic [7:0]    write_flags
  );

  logic [3:0]   read_way;

  logic         read_req_r;
  logic [8:0]   read_asid_r;
  logic [31:12] read_addr_r;
  always_ff @(posedge clk) begin
    read_req_r <= read_req;
    read_asid_r <= read_asid;
    read_addr_r <= read_addr;
  end

  // 4MiB data+tag store
  logic [8:0]   super_asid;
  logic [28:22] super_ppn;
  logic [7:0]   super_flags;

  logic [23:0] super_mem[0:1023];
  always_ff @(posedge clk) begin
    if(read_req)
      {super_asid,super_ppn,super_flags} <= super_mem[read_addr[31:22]];
    if(write_req & write_super)
      super_mem[read_addr_r[31:22]] <= {write_asid,write_ppn[28:22],write_flags};
  end
    
  // 4KiB data+tag store
  struct packed {
    // size needs to be a multiple of 8 for partial write
    logic [31:21] tag;
    logic [8:0]   asid;
    logic [28:12] ppn;
    logic [7:0]   flags;
    logic [2:0]   dummy;
  } ways[4];
  
  // silly hack needed since the vivado block ram inference is... less than ideal
  logic [191:0] data_mem_rdata;
  assign ways[0] = data_mem_rdata[47:0];
  assign ways[1] = data_mem_rdata[95:48];
  assign ways[2] = data_mem_rdata[143:96];
  assign ways[3] = data_mem_rdata[191:144];

  logic [191:0] data_mem[0:511];
  always_ff @(posedge clk) begin
    if(read_req)
      data_mem_rdata <= data_mem[read_addr[20:12]];
    if(write_req & ~write_super)
      for(int i=0;i<4;i++)
        if(read_way[i])
          data_mem[read_addr_r[20:12]][i*48+:48] <= {write_tag,write_asid,write_ppn,write_flags,3'b0};
  end

  logic [2:0] lru, lru_next;
  logic [2:0] lru_mem[0:511];
  always_ff @(posedge clk) begin
    if(read_req)
      lru <= lru_mem[read_addr[20:12]];
    if(read_req_r & read_hit)
      lru_mem[read_addr_r[20:12]] <= lru_next;
  end

  // lru update and tag check
  logic [3:0] hits;
  logic [3:0] lru_way;
  always_comb begin
    // flag 0 is the valid bit
    // flag 5 is the global bit
    read_super = super_flags[0] & (super_flags[5] | (super_asid == read_asid_r));
    for(int i=0;i<4;i++)
      hits[i] = ways[i].flags[0] & (ways[i].flags[5] | (ways[i].asid == read_asid_r)) & (ways[i].tag == read_addr_r[31:21]);

    // pseudo-lru tree
    // hit way 0/1 -> way 2/3 is lru, vice versa
    // hit way 0/2 -> way 1/3 is lru, vice versa
    lru_next[2] = ~(hits[2] | hits[3]);
    if(lru_next[2]) begin
      lru_next[1] = ~(hits[1] | hits[3]);
      lru_next[0] = lru[0];
    end else begin
      lru_next[1] = lru[1];
      lru_next[0] = ~(hits[1] | hits[3]);
    end

    // decode lru tree
    unique0 casez(lru)
      'b0?0: lru_way = 'b0001;
      'b0?1: lru_way = 'b0010;
      'b10?: lru_way = 'b0100;
      'b11?: lru_way = 'b1000;
    endcase

    // on a miss, output the lru line for quicker eviction
    read_hit = read_super | |hits;
    read_way = read_hit ? hits : lru_way;

    read_ppn = 0;
    read_flags = 0;
    if(read_super) begin
      read_ppn |= {super_ppn,10'b0};
      read_flags |= super_flags;
    end
    for(int i=0;i<4;i++)
      if(read_way[i]) begin
        read_ppn |= ways[i].ppn;
        read_flags |= ways[i].flags;
      end
  end

  // TODO will not work for synthesis
  initial begin
    for(int i=0;i<1024;i++)
      super_mem[i] = '0;
    for(int i=0;i<512;i++)
      data_mem[i] = '0;
  end

endmodule
