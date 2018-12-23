`timescale 1ns / 1ps

module synch_ram
#(
  parameter ADDR_WIDTH = 6,
  parameter DATA_WIDTH = 8
)
(
  input  wire                  clk,
  input  wire                  write_en,
  input  wire [ADDR_WIDTH-1:0] addr,
  input  wire [DATA_WIDTH-1:0] data_in,
  output wire [DATA_WIDTH-1:0] data_out
);

reg [DATA_WIDTH-1:0] ram [2**ADDR_WIDTH-1:0];
reg [ADDR_WIDTH-1:0] q_addr;

always @(posedge clk)
  begin
    if (write_en)
        ram[addr] <= data_in;
    q_addr <= addr ;
  end

assign data_out = ram[q_addr];

endmodule