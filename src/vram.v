`timescale 1ns / 1ps

module vram
(
  input  wire         clk,   // system clock
  input  wire         enable,    // chip enable
  input  wire         rw_select,  // read/write select (read: 0, write: 1)
  input  wire  [10:0] addr_in,     // memory address
  input  wire  [ 7:0] data_in,     // data input
  output wire  [ 7:0] data_out     // data output
);

wire       vram_bram_write_en;
wire [7:0] vram_bram_data_out;

synch_ram #(.ADDR_WIDTH(11),
                       .DATA_WIDTH(8)) vram_bram(
  .clk(clk),
  .write_en(vram_bram_write_en),
  .addr(addr_in),
  .data_in(data_in),
  .data_out(vram_bram_data_out)
);

assign vram_bram_write_en = (enable) ? ~rw_select       : 1'b0;
assign data_out        = (enable) ? vram_bram_data_out : 8'h00;

endmodule
