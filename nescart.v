`timescale 1ns / 1ps


module nescart(
  input  wire clk_in, // system clock 

  // Mapper config data.
  input  wire [39:0] cfg_in, // cartridge config (from iNES header)
  input  wire        cfg_upd_in, // pulse signal on cfg_in update

  // Programable ROM interface.
  input  wire        prg_nce_in, // prog-rom chip enable 
  input  wire [14:0] prg_a_in, // prog-rom address
  input  wire        prg_r_nw_in, // prog-rom r/w select
  input  wire [ 7:0] prg_d_in, // prog-rom data in
  output wire [ 7:0] prg_d_out, // prog-rom data out

  // Character-ROM interface.
  input  wire [13:0] chr_a_in, // char-rom address
  input  wire        chr_r_nw_in, // char-rom read/write select
  input  wire [ 7:0] chr_d_in, // char-rom data in
  output wire [ 7:0] chr_d_out, // char-rom data out
  output wire        ciram_nce_out, // vram chip enable 
  output wire        ciram_a10_out // vram a10 value 
);

wire        prgrom_bram_we;
wire [14:0] prgrom_bram_a;
wire [7:0]  prgrom_bram_dout;

// Block ram instance for prog-rom memory range (0x8000 - 0xFFFF).

single_port_ram_sync #(.ADDR_WIDTH(15),
                       .DATA_WIDTH(8)) prgrom_bram(
  .clk(clk_in),
  .we(prgrom_bram_we),
  .addr_a(prgrom_bram_a),
  .din_a(prg_d_in),
  .dout_a(prgrom_bram_dout)
);

assign prgrom_bram_we = (~prg_nce_in) ? ~prg_r_nw_in     : 1'b0;
assign prg_d_out      = (~prg_nce_in) ? prgrom_bram_dout : 8'h00;
assign prgrom_bram_a  = (cfg_in[33])  ? prg_a_in[14:0]   : { 1'b0, prg_a_in[13:0] };

wire       chrrom_pat_bram_we;
wire [7:0] chrrom_pat_bram_dout;

// Block ram instance for character pattern table 
single_port_ram_sync #(.ADDR_WIDTH(13),
                       .DATA_WIDTH(8)) chrrom_pat_bram(
  .clk(clk_in),
  .we(chrrom_pat_bram_we),
  .addr_a(chr_a_in[12:0]),
  .din_a(chr_d_in),
  .dout_a(chrrom_pat_bram_dout)
);

assign ciram_nce_out      = ~chr_a_in[13];
assign ciram_a10_out      = (cfg_in[16])    ? chr_a_in[10] : chr_a_in[11];
assign chrrom_pat_bram_we = (ciram_nce_out) ? ~chr_r_nw_in : 1'b0;
assign chr_d_out          = (ciram_nce_out) ? chrrom_pat_bram_dout : 8'h00;

endmodule
