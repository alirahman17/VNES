`timescale 1ns / 1ps

module wram
(
  input  wire         clk,   // system clock
  input  wire         enable,    // chip enable
  input  wire         rw_select,  // read/write select (read: 0, write: 1)
  input  wire  [10:0] addr_in,     // memory address
  input  wire  [ 7:0] data_in,     // data input
  output wire  [ 7:0] data_out     // data output
);

wire       wram_bram_write_en;
wire [7:0] wram_bram_data_out;

synch_ram #(.ADDR_WIDTH(11),
                       .DATA_WIDTH(8)) wram_bram(
  .clk(clk),
  .write_en(wram_bram_write_en),
  .addr(addr_in),
  .data_in(data_in),
  .data_out(wram_bram_data_out)
);

assign wram_bram_write_en = (enable) ? ~rw_select       : 1'b0;
assign data_out        = (enable) ? wram_bram_data_out : 8'h00;

endmodule