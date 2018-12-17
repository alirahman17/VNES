module ppu
(
  input  wire        clk_in,        // 100MHz system clock signal
  input  wire        rst_in,        // reset signal
  input  wire [ 2:0] ri_sel_in,     // register interface reg select
  input  wire        ri_ncs_in,     // register interface enable
  input  wire        ri_r_nw_in,    // register interface read/write select
  input  wire [ 7:0] ri_d_in,       // register interface data in
  input  wire [ 7:0] vram_d_in,     // video memory data bus (input)
  output wire        hsync_out,     // vga hsync signal
  output wire        vsync_out,     // vga vsync signal
  output wire [ 2:0] r_out,         // vga red signal
  output wire [ 2:0] g_out,         // vga green signal
  output wire [ 1:0] b_out,         // vga blue signal
  output wire [ 7:0] ri_d_out,      // register interface data out
  output wire        nvbl_out,      // /VBL (low during vertical blank)
  output wire [13:0] vram_a_out,    // video memory address bus
  output wire [ 7:0] vram_d_out,    // video memory data bus (output)
  output wire        vram_wr_out    // video memory read/write select
);

//
// PPU_VGA: VGA output block.
//
wire [5:0] vga_sys_palette_idx;
wire [9:0] vga_nes_x;
wire [9:0] vga_nes_y;
wire [9:0] vga_nes_y_next;
wire       vga_pix_pulse;
wire       vga_vblank;
/*
ppu_vga ppu_vga_blk(
  .clk_in(clk_in),
  .rst_in(rst_in),
  .sys_palette_idx_in(vga_sys_palette_idx),
  .hsync_out(hsync_out),
  .vsync_out(vsync_out),
  .r_out(r_out),
  .g_out(g_out),
  .b_out(b_out),
  .nes_x_out(vga_nes_x),
  .nes_y_out(vga_nes_y),
  .nes_y_next_out(vga_nes_y_next),
  .pix_pulse_out(vga_pix_pulse),
  .vblank_out(vga_vblank)
);
*/

localparam [9:0] DISPLAY_W    = 10'h280,
                 DISPLAY_H    = 10'h1E0;

// NES screen dimensions (256x240).
localparam [9:0] NES_W        = 10'h100,
                 NES_H        = 10'h0F0;

// Border color (surrounding NES screen).
localparam [7:0] BORDER_COLOR = 8'h49;

//
// VGA_SYNC: VGA synchronization control block.
//
wire       sync_en;      // vga enable signal
wire [9:0] sync_x;       // current vga x coordinate
wire [9:0] sync_y;       // current vga y coordinate
wire [9:0] sync_x_next;  // vga x coordinate for next clock
wire [9:0] sync_y_next;  // vga y coordinate for next line

vga_sync vga_sync_blk(
  .clk(clk_in),
  .hsync(hsync_out),
  .vsync(vsync_out),
  .en(sync_en),
  .x(sync_x),
  .y(sync_y),
  .x_next(sync_x_next),
  .y_next(sync_y_next)
);

//
// Registers.
//
reg  [7:0] q_rgb;     // output color latch (1 clk delay required by vga_sync)
reg  [7:0] d_rgb;
reg        q_vblank;  // current vblank state
wire       d_vblank;

always @(posedge clk_in)
  begin
    if (rst_in)
      begin
        q_rgb    <= 8'h00;
        q_vblank <= 1'h0;
      end
    else
      begin
        q_rgb    <= d_rgb;
        q_vblank <= d_vblank;
      end
  end

//
// Coord and timing signals.
//
wire [9:0] nes_x_next;  // nes x coordinate for next clock
wire       border;      // indicates we are displaying a vga pixel outside the nes extents

assign vga_nes_x      = (sync_x - 10'h040) >> 1;
assign vga_nes_y      = sync_y >> 1;
assign nes_x_next     = (sync_x_next - 10'h040) >> 1;
assign vga_nes_y_next = sync_y_next >> 1;
assign border         = (vga_nes_x >= NES_W) || (vga_nes_y < 8) || (vga_nes_y >= (NES_H - 8));

//
// Lookup RGB values based on sys_palette_idx.
//
always @*
  begin
    if (!sync_en)
      begin
        d_rgb = 8'h00;
      end
    else if (border)
      begin
        d_rgb = BORDER_COLOR;
      end
    else
      begin
        // Lookup RGB values based on sys_palette_idx.  Table is an approximation of the NES
        // system palette.  Taken from http://nesdev.parodius.com/NESTechFAQ.htm#nessnescompat.
        case (vga_sys_palette_idx)
          6'h00:  d_rgb = { 3'h3, 3'h3, 2'h1 };
          6'h01:  d_rgb = { 3'h1, 3'h0, 2'h2 };
          6'h02:  d_rgb = { 3'h0, 3'h0, 2'h2 };
          6'h03:  d_rgb = { 3'h2, 3'h0, 2'h2 };
          6'h04:  d_rgb = { 3'h4, 3'h0, 2'h1 };
          6'h05:  d_rgb = { 3'h5, 3'h0, 2'h0 };
          6'h06:  d_rgb = { 3'h5, 3'h0, 2'h0 };
          6'h07:  d_rgb = { 3'h3, 3'h0, 2'h0 };
          6'h08:  d_rgb = { 3'h2, 3'h1, 2'h0 };
          6'h09:  d_rgb = { 3'h0, 3'h2, 2'h0 };
          6'h0a:  d_rgb = { 3'h0, 3'h2, 2'h0 };
          6'h0b:  d_rgb = { 3'h0, 3'h1, 2'h0 };
          6'h0c:  d_rgb = { 3'h0, 3'h1, 2'h1 };
          6'h0d:  d_rgb = { 3'h0, 3'h0, 2'h0 };
          6'h0e:  d_rgb = { 3'h0, 3'h0, 2'h0 };
          6'h0f:  d_rgb = { 3'h0, 3'h0, 2'h0 };

          6'h10:  d_rgb = { 3'h5, 3'h5, 2'h2 };
          6'h11:  d_rgb = { 3'h0, 3'h3, 2'h3 };
          6'h12:  d_rgb = { 3'h1, 3'h1, 2'h3 };
          6'h13:  d_rgb = { 3'h4, 3'h0, 2'h3 };
          6'h14:  d_rgb = { 3'h5, 3'h0, 2'h2 };
          6'h15:  d_rgb = { 3'h7, 3'h0, 2'h1 };
          6'h16:  d_rgb = { 3'h6, 3'h1, 2'h0 };
          6'h17:  d_rgb = { 3'h6, 3'h2, 2'h0 };
          6'h18:  d_rgb = { 3'h4, 3'h3, 2'h0 };
          6'h19:  d_rgb = { 3'h0, 3'h4, 2'h0 };
          6'h1a:  d_rgb = { 3'h0, 3'h5, 2'h0 };
          6'h1b:  d_rgb = { 3'h0, 3'h4, 2'h0 };
          6'h1c:  d_rgb = { 3'h0, 3'h4, 2'h2 };
          6'h1d:  d_rgb = { 3'h0, 3'h0, 2'h0 };
          6'h1e:  d_rgb = { 3'h0, 3'h0, 2'h0 };
          6'h1f:  d_rgb = { 3'h0, 3'h0, 2'h0 };

          6'h20:  d_rgb = { 3'h7, 3'h7, 2'h3 };
          6'h21:  d_rgb = { 3'h1, 3'h5, 2'h3 };
          6'h22:  d_rgb = { 3'h2, 3'h4, 2'h3 };
          6'h23:  d_rgb = { 3'h5, 3'h4, 2'h3 };
          6'h24:  d_rgb = { 3'h7, 3'h3, 2'h3 };
          6'h25:  d_rgb = { 3'h7, 3'h3, 2'h2 };
          6'h26:  d_rgb = { 3'h7, 3'h3, 2'h1 };
          6'h27:  d_rgb = { 3'h7, 3'h4, 2'h0 };
          6'h28:  d_rgb = { 3'h7, 3'h5, 2'h0 };
          6'h29:  d_rgb = { 3'h4, 3'h6, 2'h0 };
          6'h2a:  d_rgb = { 3'h2, 3'h6, 2'h1 };
          6'h2b:  d_rgb = { 3'h2, 3'h7, 2'h2 };
          6'h2c:  d_rgb = { 3'h0, 3'h7, 2'h3 };
          6'h2d:  d_rgb = { 3'h0, 3'h0, 2'h0 };
          6'h2e:  d_rgb = { 3'h0, 3'h0, 2'h0 };
          6'h2f:  d_rgb = { 3'h0, 3'h0, 2'h0 };

          6'h30:  d_rgb = { 3'h7, 3'h7, 2'h3 };
          6'h31:  d_rgb = { 3'h5, 3'h7, 2'h3 };
          6'h32:  d_rgb = { 3'h6, 3'h6, 2'h3 };
          6'h33:  d_rgb = { 3'h6, 3'h6, 2'h3 };
          6'h34:  d_rgb = { 3'h7, 3'h6, 2'h3 };
          6'h35:  d_rgb = { 3'h7, 3'h6, 2'h3 };
          6'h36:  d_rgb = { 3'h7, 3'h5, 2'h2 };
          6'h37:  d_rgb = { 3'h7, 3'h6, 2'h2 };
          6'h38:  d_rgb = { 3'h7, 3'h7, 2'h2 };
          6'h39:  d_rgb = { 3'h7, 3'h7, 2'h2 };
          6'h3a:  d_rgb = { 3'h5, 3'h7, 2'h2 };
          6'h3b:  d_rgb = { 3'h5, 3'h7, 2'h3 };
          6'h3c:  d_rgb = { 3'h4, 3'h7, 2'h3 };
          6'h3d:  d_rgb = { 3'h0, 3'h0, 2'h0 };
          6'h3e:  d_rgb = { 3'h0, 3'h0, 2'h0 };
          6'h3f:  d_rgb = { 3'h0, 3'h0, 2'h0 };
        endcase
      end
  end

assign { r_out, g_out, b_out } = q_rgb;
assign vga_pix_pulse           = nes_x_next != vga_nes_x;

// Clear the VBLANK signal immediately before starting processing of the pre-0 garbage line.  From
// here.  Set the vblank approximately 2270 CPU cycles before it will be cleared.  This is done
// in order to pass vbl_clear_time.nes.  It eats into the visible portion of the playfield, but we
// currently hide that portion of the screen anyway.
assign d_vblank = ((sync_x == 730) && (sync_y == 477)) ? 1'b1 :
                  ((sync_x == 64) && (sync_y == 519))  ? 1'b0 : q_vblank;

assign vga_vblank = q_vblank;


//
// PPU_RI: PPU register interface block.
//
wire [7:0] ri_vram_din;
wire [7:0] ri_pram_din;
wire [7:0] ri_spr_ram_din;
wire       ri_spr_overflow;
wire       ri_spr_pri_col;
wire [7:0] ri_vram_dout;
wire       ri_vram_wr;
wire       ri_pram_wr;
wire [2:0] ri_fv;
wire [4:0] ri_vt;
wire       ri_v;
wire [2:0] ri_fh;
wire [4:0] ri_ht;
wire       ri_h;
wire       ri_s;
wire       ri_inc_addr;
wire       ri_inc_addr_amt;
wire       ri_nvbl_en;
wire       ri_vblank;
wire       ri_bg_en;
wire       ri_spr_en;
wire       ri_bg_ls_clip;
wire       ri_spr_ls_clip;
wire       ri_spr_h;
wire       ri_spr_pt_sel;
wire       ri_upd_cntrs;
wire [7:0] ri_spr_ram_a;
wire [7:0] ri_spr_ram_dout;
wire       ri_spr_ram_wr;
/*
ppu_ri ppu_ri_blk(
  .clk_in(clk_in),
  .rst_in(rst_in),
  .sel_in(ri_sel_in),
  .ncs_in(ri_ncs_in),
  .r_nw_in(ri_r_nw_in),
  .cpu_d_in(ri_d_in),
  .vram_a_in(vram_a_out),
  .vram_d_in(ri_vram_din),
  .pram_d_in(ri_pram_din),
  .vblank_in(vga_vblank),
  .spr_ram_d_in(ri_spr_ram_din),
  .spr_overflow_in(ri_spr_overflow),
  .spr_pri_col_in(ri_spr_pri_col),
  .cpu_d_out(ri_d_out),
  .vram_d_out(ri_vram_dout),
  .vram_wr_out(ri_vram_wr),
  .pram_wr_out(ri_pram_wr),
  .fv_out(ri_fv),
  .vt_out(ri_vt),
  .v_out(ri_v),
  .fh_out(ri_fh),
  .ht_out(ri_ht),
  .h_out(ri_h),
  .s_out(ri_s),
  .inc_addr_out(ri_inc_addr),
  .inc_addr_amt_out(ri_inc_addr_amt),
  .nvbl_en_out(ri_nvbl_en),
  .vblank_out(ri_vblank),
  .bg_en_out(ri_bg_en),
  .spr_en_out(ri_spr_en),
  .bg_ls_clip_out(ri_bg_ls_clip),
  .spr_ls_clip_out(ri_spr_ls_clip),
  .spr_h_out(ri_spr_h),
  .spr_pt_sel_out(ri_spr_pt_sel),
  .upd_cntrs_out(ri_upd_cntrs),
  .spr_ram_a_out(ri_spr_ram_a),
  .spr_ram_d_out(ri_spr_ram_dout),
  .spr_ram_wr_out(ri_spr_ram_wr)
);
*/

reg [2:0] q_fv,  d_fv;   // fine vertical scroll latch
reg [4:0] q_vt,  d_vt;   // vertical tile index latch
reg       q_v,   d_v;    // vertical name table selection latch
reg [2:0] q_fh,  d_fh;   // fine horizontal scroll latch
reg [4:0] q_ht,  d_ht;   // horizontal tile index latch
reg       q_h,   d_h;    // horizontal name table selection latch
reg       q_s,   d_s;    // playfield pattern table selection latch

//
// Output Latches
//
reg [7:0] q_ri_d_out,     d_ri_d_out;      // output data bus latch for 0x2007 reads
reg       q_ri_upd_cntrs, d_ri_upd_cntrs;  // output latch for ri_upd_cntrs

//
// External State Registers
//
reg q_nvbl_en,     d_nvbl_en;     // 0x2000[7]: enables an NMI interrupt on vblank
reg q_spr_h,       d_spr_h;       // 0x2000[5]: select 8/16 scanline high sprites
reg q_spr_pt_sel,  d_spr_pt_sel;  // 0x2000[3]: sprite pattern table select
reg q_addr_incr,   d_addr_incr;   // 0x2000[2]: amount to increment addr on 0x2007 access.
                                  //            0: 1 byte, 1: 32 bytes.
reg q_spr_en,      d_spr_en;      // 0x2001[4]: enables sprite rendering
reg q_bg_en,       d_bg_en;       // 0x2001[3]: enables background rendering
reg q_spr_ls_clip, d_spr_ls_clip; // 0x2001[2]: left side screen column (8 pixel) object clipping
reg q_bg_ls_clip,  d_bg_ls_clip;  // 0x2001[1]: left side screen column (8 pixel) bg clipping
reg q_vblank,      d_vblank;      // 0x2002[7]: indicates a vblank is occurring

//
// Internal State Registers
//
reg       q_byte_sel,  d_byte_sel;   // tracks if next 0x2005/0x2006 write is high or low byte
reg [7:0] q_rd_buf,    d_rd_buf;     // internal latch for buffered 0x2007 reads
reg       q_rd_rdy,    d_rd_rdy;     // controls q_rd_buf updates
reg [7:0] q_spr_ram_a, d_spr_ram_a;  // sprite ram pointer (set on 0x2003 write)

reg       q_ri_ncs_in;                  // last ncs signal (to detect falling edges)
reg       q_vga_vblank;               // last vga_vblank signal (to detect falling edges)

always @(posedge clk_in)
  begin
    if (rst_in)
      begin
        q_fv            <= 2'h0;
        q_vt            <= 5'h00;
        q_v             <= 1'h0;
        q_fh            <= 3'h0;
        q_ht            <= 5'h00;
        q_h             <= 1'h0;
        q_s             <= 1'h0;
        q_ri_d_out     <= 8'h00;
        q_ri_upd_cntrs <= 1'h0;
        q_nvbl_en       <= 1'h0;
        q_spr_h         <= 1'h0;
        q_spr_pt_sel    <= 1'h0;
        q_addr_incr     <= 1'h0;
        q_spr_en        <= 1'h0;
        q_bg_en         <= 1'h0;
        q_spr_ls_clip   <= 1'h0;
        q_bg_ls_clip    <= 1'h0;
        q_vblank        <= 1'h0;
        q_byte_sel      <= 1'h0;
        q_rd_buf        <= 8'h00;
        q_rd_rdy        <= 1'h0;
        q_spr_ram_a     <= 8'h00;
        q_ri_ncs_in        <= 1'h1;
        q_vga_vblank     <= 1'h0;
      end
    else
      begin
        q_fv            <= d_fv;
        q_vt            <= d_vt;
        q_v             <= d_v;
        q_fh            <= d_fh;
        q_ht            <= d_ht;
        q_h             <= d_h;
        q_s             <= d_s;
        q_ri_d_out     <= d_ri_d_out;
        q_ri_upd_cntrs <= d_ri_upd_cntrs;
        q_nvbl_en       <= d_nvbl_en;
        q_spr_h         <= d_spr_h;
        q_spr_pt_sel    <= d_spr_pt_sel;
        q_addr_incr     <= d_addr_incr;
        q_spr_en        <= d_spr_en;
        q_bg_en         <= d_bg_en;
        q_spr_ls_clip   <= d_spr_ls_clip;
        q_bg_ls_clip    <= d_bg_ls_clip;
        q_vblank        <= d_vblank;
        q_byte_sel      <= d_byte_sel;
        q_rd_buf        <= d_rd_buf;
        q_rd_rdy        <= d_rd_rdy;
        q_spr_ram_a     <= d_spr_ram_a;
        q_ri_ncs_in        <= ri_ncs_in;
        q_vga_vblank     <= vga_vblank;
      end
  end

always @*
  begin
    // Default most state to its original value.
    d_fv          = q_fv;
    d_vt          = q_vt;
    d_v           = q_v;
    d_fh          = q_fh;
    d_ht          = q_ht;
    d_h           = q_h;
    d_s           = q_s;
    d_ri_d_out   = q_ri_d_out;
    d_nvbl_en     = q_nvbl_en;
    d_spr_h       = q_spr_h;
    d_spr_pt_sel  = q_spr_pt_sel;
    d_addr_incr   = q_addr_incr;
    d_spr_en      = q_spr_en;
    d_bg_en       = q_bg_en;
    d_spr_ls_clip = q_spr_ls_clip;
    d_bg_ls_clip  = q_bg_ls_clip;
    d_byte_sel    = q_byte_sel;
    d_spr_ram_a   = q_spr_ram_a;

    // Update the read buffer if a new read request is ready.  This happens one cycle after a read
    // of 0x2007.
    d_rd_buf = (q_rd_rdy) ? ri_vram_din : q_rd_buf;
    d_rd_rdy = 1'b0;

    // Request a PPU counter update only after second write to 0x2006.
    d_ri_upd_cntrs = 1'b0;

    // Set the vblank status bit on a rising vblank edge.  Clear it if vblank is false.  Can also
    // be cleared by reading 0x2002.
    d_vblank = (~q_vga_vblank & vga_vblank) ? 1'b1 :
               (~vga_vblank)               ? 1'b0 : q_vblank;

    // Only request memory writes on write of 0x2007.
    ri_vram_wr = 1'b0;
    ri_vram_dout  = 8'h00;
    ri_pram_wr = 1'b0;

    // Only request VRAM addr increment on access of 0x2007.
    ri_inc_addr = 1'b0;

    ri_spr_ram_dout  = 8'h00;
    ri_spr_ram_wr = 1'b0;

    // Only evaluate RI reads/writes on /CS falling edges.  This prevents executing the same
    // command multiple times because the CPU runs at a slower clock rate than the PPU.
    if (q_ri_ncs_in & ~ri_ncs_in)
      begin
        if (r_nw_in)
          begin
            // External register read.
            case (ri_sel_in)
              3'h2:  // 0x2002
                begin
                  d_ri_d_out = { q_vblank, ri_spr_pri_col, ri_spr_overflow, 5'b00000 };
                  d_byte_sel  = 1'b0;
                  d_vblank    = 1'b0;
                end
              3'h4:  // 0x2004
                begin
                  d_ri_d_out = ri_spr_ram_din;
                end
              3'h7:  // 0x2007
                begin
                  d_ri_d_out  = (vram_a_out[13:8] == 6'h3F) ? ri_pram_din : q_rd_buf;
                  d_rd_rdy     = 1'b1;
                  ri_inc_addr = 1'b1;
                end
            endcase
          end
        else
          begin
            // External register write.
            case (ri_sel_in)
              3'h0:  // 0x2000
                begin
                  d_nvbl_en    = cpu_d_in[7];
                  d_spr_h      = cpu_d_in[5];
                  d_s          = cpu_d_in[4];
                  d_spr_pt_sel = cpu_d_in[3];
                  d_addr_incr  = cpu_d_in[2];
                  d_v          = cpu_d_in[1];
                  d_h          = cpu_d_in[0];
                end
              3'h1:  // 0x2001
                begin
                  d_spr_en      = cpu_d_in[4];
                  d_bg_en       = cpu_d_in[3];
                  d_spr_ls_clip = ~cpu_d_in[2];
                  d_bg_ls_clip  = ~cpu_d_in[1];
                end
              3'h3:  // 0x2003
                begin
                  d_spr_ram_a = cpu_d_in;
                end
              3'h4:  // 0x2004
                begin
                  ri_spr_ram_dout  = cpu_d_in;
                  ri_spr_ram_wr = 1'b1;
                  d_spr_ram_a    = q_spr_ram_a + 8'h01;
                end
              3'h5:  // 0x2005
                begin
                  d_byte_sel = ~q_byte_sel;
                  if (~q_byte_sel)
                    begin
                      // First write.
                      d_fh = cpu_d_in[2:0];
                      d_ht = cpu_d_in[7:3];
                    end
                  else
                    begin
                      // Second write.
                      d_fv = cpu_d_in[2:0];
                      d_vt = cpu_d_in[7:3];
                    end
                end
              3'h6:  // 0x2006
                begin
                  d_byte_sel = ~q_byte_sel;
                  if (~q_byte_sel)
                    begin
                      // First write.
                      d_fv      = { 1'b0, cpu_d_in[5:4] };
                      d_v       = cpu_d_in[3];
                      d_h       = cpu_d_in[2];
                      d_vt[4:3] = cpu_d_in[1:0];
                    end
                  else
                    begin
                      // Second write.
                      d_vt[2:0]       = cpu_d_in[7:5];
                      d_ht            = cpu_d_in[4:0];
                      d_ri_upd_cntrs = 1'b1;
                    end
                end
              3'h7:  // 0x2007
                begin
                  if (vram_a_out[13:8] == 6'h3F)
                    ri_pram_wr = 1'b1;
                  else
                    ri_vram_wr = 1'b1;

                  ri_vram_dout   = cpu_d_in;
                  ri_inc_addr = 1'b1;
                end
            endcase
          end
      end
  end

assign ri_d_out        = (~ri_ncs_in & r_nw_in) ? q_ri_d_out : 8'h00;
assign ri_fv           = q_fv;
assign ri_vt           = q_vt;
assign ri_v            = q_v;
assign ri_fh           = q_fh;
assign ri_ht           = q_ht;
assign ri_h            = q_h;
assign ri_s            = q_s;
assign ri_inc_addr_amt = q_addr_incr;
assign ri_nvbl_en      = q_nvbl_en;
assign ri_vblank       = q_vblank;
assign ri_bg_en        = q_bg_en;
assign ri_spr_en       = q_spr_en;
assign ri_bg_ls_clip   = q_bg_ls_clip;
assign ri_spr_ls_clip  = q_spr_ls_clip;
assign ri_spr_h        = q_spr_h;
assign ri_spr_pt_sel   = q_spr_pt_sel;
assign ri_upd_cntrs    = q_ri_upd_cntrs;
assign ri_spr_ram_a    = q_spr_ram_a;


//
// PPU_BG: PPU backgroud/playfield generator block.
//
wire [13:0] bg_vram_a;
wire [ 3:0] bg_palette_idx;
/*
ppu_bg ppu_bg_blk(
  .clk_in(clk_in),
  .rst_in(rst_in),
  .en_in(ri_bg_en),
  .ls_clip_in(ri_bg_ls_clip),
  .fv_in(ri_fv),
  .vt_in(ri_vt),
  .v_in(ri_v),
  .fh_in(ri_fh),
  .ht_in(ri_ht),
  .h_in(ri_h),
  .s_in(ri_s),
  .nes_x_in(vga_nes_x),
  .nes_y_in(vga_nes_y),
  .vga_nes_y_next(vga_nes_y_next),
  .vga_pix_pulse(vga_pix_pulse),
  .vram_d_in(vram_d_in),
  .ri_upd_cntrs_in(ri_upd_cntrs),
  .ri_inc_addr_in(ri_inc_addr),
  .ri_inc_addr_amt_in(ri_inc_addr_amt),
  .vram_a_out(bg_vram_a),
  .spr_palette_idx(bg_palette_idx)
);
*/

reg [ 2:0] q_fvc,           d_fvc;            // fine vertical scroll counter
reg [ 4:0] q_vtc,           d_vtc;            // vertical tile index counter
reg        q_vc,            d_vc;             // vertical name table selection counter
reg [ 4:0] q_htc,           d_htc;            // horizontal tile index counter
reg        q_hc,            d_hc;             // horizontal name table selection counter

reg [ 7:0] q_par,           d_par;            // picture address register (holds tile index)
reg [ 1:0] q_ar,            d_ar;             // tile attribute value latch (bits 3 and 2)
reg [ 7:0] q_pd0,           d_pd0;            // palette data 0 (bit 0 for tile)
reg [ 7:0] q_pd1,           d_pd1;            // palette data 1 (bit 1 for tile)

reg [ 8:0] q_bg_bit3_shift, d_bg_bit3_shift;  // shift register with per-pixel bg palette idx bit 3
reg [ 8:0] q_bg_bit2_shift, d_bg_bit2_shift;  // shift register with per-pixel bg palette idx bit 2
reg [15:0] q_bg_bit1_shift, d_bg_bit1_shift;  // shift register with per-pixel bg palette idx bit 1
reg [15:0] q_bg_bit0_shift, d_bg_bit0_shift;  // shift register with per-pixel bg palette idx bit 0

always @(posedge clk_in)
  begin
    if (rst_in)
      begin
        q_fvc           <=  2'h0;
        q_vtc           <=  5'h00;
        q_vc            <=  1'h0;
        q_htc           <=  5'h00;
        q_hc            <=  1'h0;
        q_par           <=  8'h00;
        q_ar            <=  2'h0;
        q_pd0           <=  8'h00;
        q_pd1           <=  8'h00;
        q_bg_bit3_shift <=  9'h000;
        q_bg_bit2_shift <=  9'h000;
        q_bg_bit1_shift <= 16'h0000;
        q_bg_bit0_shift <= 16'h0000;
      end
    else
      begin
        q_fvc           <= d_fvc;
        q_vtc           <= d_vtc;
        q_vc            <= d_vc;
        q_htc           <= d_htc;
        q_hc            <= d_hc;
        q_par           <= d_par;
        q_ar            <= d_ar;
        q_pd0           <= d_pd0;
        q_pd1           <= d_pd1;
        q_bg_bit3_shift <= d_bg_bit3_shift;
        q_bg_bit2_shift <= d_bg_bit2_shift;
        q_bg_bit1_shift <= d_bg_bit1_shift;
        q_bg_bit0_shift <= d_bg_bit0_shift;
      end
  end

//
// Scroll counter management.
//
reg upd_v_cntrs;
reg upd_h_cntrs;
reg inc_v_cntrs;
reg inc_h_cntrs;

always @*
  begin
    // Default to original values.
    d_fvc = q_fvc;
    d_vc  = q_vc;
    d_hc  = q_hc;
    d_vtc = q_vtc;
    d_htc = q_htc;

    if (ri_inc_addr)
      begin
        // If the VRAM address increment bit (2000.2) is clear (inc. amt. = 1), all the scroll
        // counters are daisy-chained (in the order of HT, VT, H, V, FV) so that the carry out of
        // each counter controls the next counter's clock rate. The result is that all 5 counters
        // function as a single 15-bit one. Any access to 2007 clocks the HT counter here.
        //
        // If the VRAM address increment bit is set (inc. amt. = 32), the only difference is that
        // the HT counter is no longer being clocked, and the VT counter is now being clocked by
        // access to 2007.
        if (ri_inc_addr_amt)
          { d_fvc, d_vc, d_hc, d_vtc } = { q_fvc, q_vc, q_hc, q_vtc } + 10'h001;
        else
          { d_fvc, d_vc, d_hc, d_vtc, d_htc } = { q_fvc, q_vc, q_hc, q_vtc, q_htc } + 15'h0001;
      end
    else
      begin
        if (inc_v_cntrs)
          begin
            // The vertical scroll counter is 9 bits, and is made up by daisy-chaining FV to VT, and
            // VT to V. FV is clocked by the PPU's horizontal blanking impulse, and therefore will
            // increment every scanline. VT operates here as a divide-by-30 counter, and will only
            // generate a carry condition when the count increments from 29 to 30 (the counter will
            // also reset). Dividing by 30 is neccessary to prevent attribute data in the name
            // tables from being used as tile index data.
            if ({ q_vtc, q_fvc } == { 5'b1_1101, 3'b111 })
              { d_vc, d_vtc, d_fvc } = { ~q_vc, 8'h00 };
            else
              { d_vc, d_vtc, d_fvc } = { q_vc, q_vtc, q_fvc } + 9'h001;
          end

        if (inc_h_cntrs)
          begin
            // The horizontal scroll counter consists of 6 bits, and is made up by daisy-chaining the
            // HT counter to the H counter. The HT counter is then clocked every 8 pixel dot clocks
            // (or every 8/3 CPU clock cycles).
            { d_hc, d_htc } = { q_hc, q_htc } + 6'h01;
          end

        // Counter loading. There are 2 conditions that update all 5 PPU scroll counters with the
        // contents of the latches adjacent to them. The first is after a write to 2006/2. The
        // second, is at the beginning of scanline 20, when the PPU starts rendering data for the
        // first time in a frame (this update won't happen if all rendering is disabled via 2001.3
        // and 2001.4).
        //
        // There is one condition that updates the H & HT counters, and that is at the end of the
        // horizontal blanking period of a scanline. Again, image rendering must be occuring for
        // this update to be effective.
        if (upd_v_cntrs || ri_upd_cntrs)
          begin
            d_vc  = ri_v;
            d_vtc = ri_vt;
            d_fvc = ri_fv;
          end

        if (upd_h_cntrs || ri_upd_cntrs)
          begin
            d_hc  = ri_h;
            d_htc = ri_ht;
          end
      end
  end

//
// VRAM address derivation logic.
//
localparam [2:0] VRAM_A_SEL_RI       = 3'h0,
                 VRAM_A_SEL_NT_READ  = 3'h1,
                 VRAM_A_SEL_AT_READ  = 3'h2,
                 VRAM_A_SEL_PT0_READ = 3'h3,
                 VRAM_A_SEL_PT1_READ = 3'h4;

reg [2:0] vram_a_sel;

always @*
  begin
    case (vram_a_sel)
      VRAM_A_SEL_NT_READ:
        bg_vram_a = { 2'b10, q_vc, q_hc, q_vtc, q_htc };
      VRAM_A_SEL_AT_READ:
        bg_vram_a = { 2'b10, q_vc, q_hc, 4'b1111, q_vtc[4:2], q_htc[4:2] };
      VRAM_A_SEL_PT0_READ:
        bg_vram_a = { 1'b0, ri_s, q_par, 1'b0, q_fvc };
      VRAM_A_SEL_PT1_READ:
        bg_vram_a = { 1'b0, ri_s, q_par, 1'b1, q_fvc };
      default:
        bg_vram_a = { q_fvc[1:0], q_vc, q_hc, q_vtc, q_htc };
    endcase
  end

//
// Background palette index derivation logic.
//
wire clip;

always @*
  begin
    // Default to original value.
    d_par           = q_par;
    d_ar            = q_ar;
    d_pd0           = q_pd0;
    d_pd1           = q_pd1;
    d_bg_bit3_shift = q_bg_bit3_shift;
    d_bg_bit2_shift = q_bg_bit2_shift;
    d_bg_bit1_shift = q_bg_bit1_shift;
    d_bg_bit0_shift = q_bg_bit0_shift;

    upd_v_cntrs = 1'b0;
    inc_v_cntrs = 1'b0;
    upd_h_cntrs = 1'b0;
    inc_h_cntrs = 1'b0;

    vram_a_sel = VRAM_A_SEL_RI;

    if (ri_bg_en && ((vga_nes_y < 239) || (nes_y_next_in == 0)))
      begin
        if (pix_pulse_in && (vga_nes_x == 319))
          begin
            upd_h_cntrs = 1'b1;

            if (nes_y_next_in != vga_nes_y)
              begin
                if (nes_y_next_in == 0)
                  upd_v_cntrs = 1'b1;
                else
                  inc_v_cntrs = 1'b1;
              end
          end

        if ((vga_nes_x < 256) || ((vga_nes_x >= 320 && vga_nes_x < 336)))
          begin
            if (pix_pulse_in)
              begin
                d_bg_bit3_shift = { q_bg_bit3_shift[8], q_bg_bit3_shift[8:1] };
                d_bg_bit2_shift = { q_bg_bit2_shift[8], q_bg_bit2_shift[8:1] };
                d_bg_bit1_shift = { 1'b0, q_bg_bit1_shift[15:1] };
                d_bg_bit0_shift = { 1'b0, q_bg_bit0_shift[15:1] };
              end

            if (pix_pulse_in && (vga_nes_x[2:0] == 3'h7))
              begin
                inc_h_cntrs         = 1'b1;

                d_bg_bit3_shift[8]  = q_ar[1];
                d_bg_bit2_shift[8]  = q_ar[0];

                d_bg_bit1_shift[15] = q_pd1[0];
                d_bg_bit1_shift[14] = q_pd1[1];
                d_bg_bit1_shift[13] = q_pd1[2];
                d_bg_bit1_shift[12] = q_pd1[3];
                d_bg_bit1_shift[11] = q_pd1[4];
                d_bg_bit1_shift[10] = q_pd1[5];
                d_bg_bit1_shift[ 9] = q_pd1[6];
                d_bg_bit1_shift[ 8] = q_pd1[7];

                d_bg_bit0_shift[15] = q_pd0[0];
                d_bg_bit0_shift[14] = q_pd0[1];
                d_bg_bit0_shift[13] = q_pd0[2];
                d_bg_bit0_shift[12] = q_pd0[3];
                d_bg_bit0_shift[11] = q_pd0[4];
                d_bg_bit0_shift[10] = q_pd0[5];
                d_bg_bit0_shift[ 9] = q_pd0[6];
                d_bg_bit0_shift[ 8] = q_pd0[7];
              end

            case (vga_nes_x[2:0])
              3'b000:
                begin
                  vram_a_sel = VRAM_A_SEL_NT_READ;
                  d_par      = vram_d_in;
                end
              3'b001:
                begin
                  vram_a_sel = VRAM_A_SEL_AT_READ;
                  d_ar       = vram_d_in >> { q_vtc[1], q_htc[1], 1'b0 };
                end
              3'b010:
                begin
                  vram_a_sel = VRAM_A_SEL_PT0_READ;
                  d_pd0      = vram_d_in;
                end
              3'b011:
                begin
                  vram_a_sel = VRAM_A_SEL_PT1_READ;
                  d_pd1      = vram_d_in;
                end
            endcase
          end
      end
  end

assign clip            = ri_bg_ls_clip && (vga_nes_x >= 10'h000) && (vga_nes_x < 10'h008);
assign bg_palette_idx = (!clip && ri_bg_en) ? { q_bg_bit3_shift[ri_fh],
                                              q_bg_bit2_shift[ri_fh],
                                              q_bg_bit1_shift[ri_fh],
                                              q_bg_bit0_shift[ri_fh] } : 4'h0;



//
// PPU_SPR: PPU sprite generator block.
//
wire  [3:0] spr_palette_idx;
wire        spr_primary;
wire        spr_priority;
wire [13:0] spr_vram_a;
wire        spr_vram_req;
/*
ppu_spr ppu_spr_blk(
  .clk_in(clk_in),
  .rst_in(rst_in),
  .en_in(ri_spr_en),
  .ls_clip_in(ri_spr_ls_clip),
  .spr_h_in(ri_spr_h),
  .spr_pt_sel_in(ri_spr_pt_sel),
  .oam_a_in(ri_spr_ram_a),
  .oam_d_in(ri_spr_ram_dout),
  .oam_wr_in(ri_spr_ram_wr),
  .nes_x_in(vga_nes_x),
  .nes_y_in(vga_nes_y),
  .vga_nes_y_next(vga_nes_y_next),
  .vga_pix_pulse(vga_pix_pulse),
  .vram_d_in(vram_d_in),
  .oam_d_out(ri_spr_ram_din),
  .overflow_out(ri_spr_overflow),
  .spr_palette_idx(spr_palette_idx),
  .primary_out(spr_primary),
  .priority_out(spr_priority),
  .vram_a_out(spr_vram_a),
  .vram_req_out(spr_vram_req)
);*/

reg [7:0] m_oam [255:0];

always @(posedge clk_in)
  begin
    if (ri_spr_ram_wr)
      m_oam[ri_spr_ram_a] <= ri_spr_ram_dout;
  end

// STM: Sprite Temporary Memory
//
// bits     desc
// -------  -----
//      24  primary object flag (is sprite 0?)
// 23 : 16  tile index
// 15 :  8  x coordinate
//  7 :  6  palette select bits
//       5  object priority
//       4  apply bit reversal to fetched object pattern table data (horizontal invert)
//  3 :  0  range comparison result (sprite row)
reg [24:0] m_stm [7:0];

reg [24:0] stm_din;
reg [ 2:0] stm_a;
reg        stm_wr;

always @(posedge clk_in)
  begin
    if (stm_wr)
      m_stm[stm_a] <= stm_din;
  end

// SBM: Sprite Buffer Memory
//
// bits     desc
// -------  -----
//      27  primary object flag (is sprite 0?)
//      26  priority
// 25 - 24  palette select (bit 3-2)
// 23 - 16  pattern data bit 1
// 15 -  8  pattern data bit 0
//  7 -  0  x-start
reg [27:0] m_sbm [7:0];

reg [27:0] sbm_din;
reg [ 2:0] sbm_a;
reg        sbm_wr;

always @(posedge clk_in)
  begin
    if (sbm_wr)
      m_sbm[sbm_a] <= sbm_din;
  end

//
// In-range object evaluation (line N-1, fetch phases 1-128).
//
reg [3:0] q_in_rng_cnt,   d_in_rng_cnt;    // number of objects on the next scanline
reg       q_spr_overflow, d_spr_overflow;  // signals more than 8 objects on a scanline this frame

always @(posedge clk_in)
  begin
    if (rst_in)
      begin
        q_in_rng_cnt   <= 4'h0;
        q_spr_overflow <= 1'h0;
      end
    else
      begin
        q_in_rng_cnt   <= d_in_rng_cnt;
        q_spr_overflow <= d_spr_overflow;
      end
  end

wire [5:0] oam_rd_idx;       // oam entry selector
wire [7:0] oam_rd_y;         // cur oam entry y coordinate
wire [7:0] oam_rd_tile_idx;  // cur oam entry tile index
wire       oam_rd_v_inv;     // cur oam entry vertical inversion state
wire       oam_rd_h_inv;     // cur oam entry horizontal inversion state
wire       oam_rd_priority;  // cur oam entry priority
wire [1:0] oam_rd_ps;        // cur oam entry palette select
wire [7:0] oam_rd_x;         // cur oam entry x coordinate

wire [8:0] rng_cmp_res;      // 9-bit comparison result for in-range check
wire       in_rng;           // indicates whether current object is in-range

assign oam_rd_idx      = vga_nes_x[7:2];

assign oam_rd_y        = m_oam[{ oam_rd_idx, 2'b00 }] + 8'h01;
assign oam_rd_tile_idx = m_oam[{ oam_rd_idx, 2'b01 }];
assign oam_rd_v_inv    = m_oam[{ oam_rd_idx, 2'b10 }] >> 3'h7;
assign oam_rd_h_inv    = m_oam[{ oam_rd_idx, 2'b10 }] >> 3'h6;
assign oam_rd_priority = m_oam[{ oam_rd_idx, 2'b10 }] >> 3'h5;
assign oam_rd_ps       = m_oam[{ oam_rd_idx, 2'b10 }];
assign oam_rd_x        = m_oam[{ oam_rd_idx, 2'b11 }];

assign rng_cmp_res     = nes_y_next_in - oam_rd_y;
assign in_rng          = (~|rng_cmp_res[8:4]) & (~rng_cmp_res[3] | ri_spr_h);

always @*
  begin
    d_in_rng_cnt  = q_in_rng_cnt;

    // Reset the sprite overflow flag at the beginning of each frame.  Otherwise, set the flag if
    // any scanline in this frame has intersected more than 8 sprites.
    if ((nes_y_next_in == 0) && (vga_nes_x == 0))
      d_spr_overflow = 1'b0;
    else
      d_spr_overflow = q_spr_overflow || q_in_rng_cnt[3];

    stm_a  = q_in_rng_cnt[2:0];
    stm_wr = 1'b0;

    stm_din[   24] = ~|oam_rd_idx;
    stm_din[23:16] = oam_rd_tile_idx;
    stm_din[15: 8] = oam_rd_x;
    stm_din[ 7: 6] = oam_rd_ps;
    stm_din[    5] = oam_rd_priority;
    stm_din[    4] = oam_rd_h_inv;
    stm_din[ 3: 0] = (oam_rd_v_inv) ? ~rng_cmp_res[3:0] : rng_cmp_res[3:0];

    if (ri_spr_en && pix_pulse_in && (nes_y_next_in < 239))
      begin
        if (vga_nes_x == 320)
          begin
            // Reset the in-range count and sprite 0 in-rnage flag at the end of each scanline.
            d_in_rng_cnt  = 4'h0;
          end
        else if ((vga_nes_x < 256) && (vga_nes_x[1:0] == 2'h0) && in_rng && !q_in_rng_cnt[3])
          begin
            // Current object is in range, and there are less than 8 in-range objects found
            // so far.  Update the STM and increment the in-range counter.
            stm_wr       = 1'b1;
            d_in_rng_cnt = q_in_rng_cnt + 4'h1;
          end
      end
  end

//
// Object pattern fetch (fetch phases 129-160).
//
reg [7:0] q_pd0, d_pd0;
reg [7:0] q_pd1, d_pd1;

always @(posedge clk_in)
  begin
    if (rst_in)
      begin
        q_pd1 <= 8'h00;
        q_pd0 <= 8'h00;
      end
    else
      begin
        q_pd1 <= d_pd1;
        q_pd0 <= d_pd0;
      end
  end

wire [2:0] stm_rd_idx;
wire       stm_rd_primary;
wire [7:0] stm_rd_tile_idx;
wire [7:0] stm_rd_x;
wire [1:0] stm_rd_ps;
wire       stm_rd_priority;
wire       stm_rd_h_inv;
wire [3:0] stm_rd_obj_row;

assign stm_rd_idx      = vga_nes_x[5:3];
assign stm_rd_primary  = m_stm[stm_rd_idx] >> 24;
assign stm_rd_tile_idx = m_stm[stm_rd_idx] >> 16;
assign stm_rd_x        = m_stm[stm_rd_idx] >> 8;
assign stm_rd_ps       = m_stm[stm_rd_idx] >> 6;
assign stm_rd_priority = m_stm[stm_rd_idx] >> 5;
assign stm_rd_h_inv    = m_stm[stm_rd_idx] >> 4;
assign stm_rd_obj_row  = m_stm[stm_rd_idx];

always @*
  begin
    d_pd1 = q_pd1;
    d_pd0 = q_pd0;

    sbm_a   = stm_rd_idx;
    sbm_wr  = 1'b0;
    sbm_din = 28'h000;

    spr_vram_req = 1'b0;

    if (ri_spr_h)
      spr_vram_a = { 1'b0,
                     stm_rd_tile_idx[0],
                     stm_rd_tile_idx[7:1],
                     stm_rd_obj_row[3],
                     vga_nes_x[1],
                     stm_rd_obj_row[2:0] };
    else
      spr_vram_a = { 1'b0,
                     ri_spr_pt_sel,
                     stm_rd_tile_idx,
                     vga_nes_x[1],
                     stm_rd_obj_row[2:0] };

    if (ri_spr_en && (nes_y_next_in < 239) && (vga_nes_x >= 256) && (vga_nes_x < 320))
      begin
        if (stm_rd_idx < q_in_rng_cnt)
          begin
            case (vga_nes_x[2:1])
              2'h0:
                begin
                  spr_vram_req = 1'b1;

                  if (stm_rd_h_inv)
                    begin
                      d_pd0 = vram_d_in;
                    end
                  else
                    begin
                      d_pd0[0] = vram_d_in[7];
                      d_pd0[1] = vram_d_in[6];
                      d_pd0[2] = vram_d_in[5];
                      d_pd0[3] = vram_d_in[4];
                      d_pd0[4] = vram_d_in[3];
                      d_pd0[5] = vram_d_in[2];
                      d_pd0[6] = vram_d_in[1];
                      d_pd0[7] = vram_d_in[0];
                    end
                end
              2'h1:
                begin
                  spr_vram_req = 1'b1;

                  if (stm_rd_h_inv)
                    begin
                      d_pd1 = vram_d_in;
                    end
                  else
                    begin
                      d_pd1[0] = vram_d_in[7];
                      d_pd1[1] = vram_d_in[6];
                      d_pd1[2] = vram_d_in[5];
                      d_pd1[3] = vram_d_in[4];
                      d_pd1[4] = vram_d_in[3];
                      d_pd1[5] = vram_d_in[2];
                      d_pd1[6] = vram_d_in[1];
                      d_pd1[7] = vram_d_in[0];
                    end
                end
              2'h2:
                begin
                  sbm_din = { stm_rd_primary, stm_rd_priority, stm_rd_ps, q_pd1, q_pd0, stm_rd_x };
                  sbm_wr  = 1'b1;
                end
            endcase
          end
        else
          begin
            sbm_din = 28'h0000000;
            sbm_wr  = 1'b1;
          end
      end
  end

//
// Object prioritization and output (line N, fetch phases 1-128).
//
reg  [7:0] q_obj0_pd1_shift, d_obj0_pd1_shift;
reg  [7:0] q_obj1_pd1_shift, d_obj1_pd1_shift;
reg  [7:0] q_obj2_pd1_shift, d_obj2_pd1_shift;
reg  [7:0] q_obj3_pd1_shift, d_obj3_pd1_shift;
reg  [7:0] q_obj4_pd1_shift, d_obj4_pd1_shift;
reg  [7:0] q_obj5_pd1_shift, d_obj5_pd1_shift;
reg  [7:0] q_obj6_pd1_shift, d_obj6_pd1_shift;
reg  [7:0] q_obj7_pd1_shift, d_obj7_pd1_shift;
reg  [7:0] q_obj0_pd0_shift, d_obj0_pd0_shift;
reg  [7:0] q_obj1_pd0_shift, d_obj1_pd0_shift;
reg  [7:0] q_obj2_pd0_shift, d_obj2_pd0_shift;
reg  [7:0] q_obj3_pd0_shift, d_obj3_pd0_shift;
reg  [7:0] q_obj4_pd0_shift, d_obj4_pd0_shift;
reg  [7:0] q_obj5_pd0_shift, d_obj5_pd0_shift;
reg  [7:0] q_obj6_pd0_shift, d_obj6_pd0_shift;
reg  [7:0] q_obj7_pd0_shift, d_obj7_pd0_shift;

always @(posedge clk_in)
  begin
    if (rst_in)
      begin
        q_obj0_pd1_shift <= 8'h00;
        q_obj1_pd1_shift <= 8'h00;
        q_obj2_pd1_shift <= 8'h00;
        q_obj3_pd1_shift <= 8'h00;
        q_obj4_pd1_shift <= 8'h00;
        q_obj5_pd1_shift <= 8'h00;
        q_obj6_pd1_shift <= 8'h00;
        q_obj7_pd1_shift <= 8'h00;
        q_obj0_pd0_shift <= 8'h00;
        q_obj1_pd0_shift <= 8'h00;
        q_obj2_pd0_shift <= 8'h00;
        q_obj3_pd0_shift <= 8'h00;
        q_obj4_pd0_shift <= 8'h00;
        q_obj5_pd0_shift <= 8'h00;
        q_obj6_pd0_shift <= 8'h00;
        q_obj7_pd0_shift <= 8'h00;
      end
    else
      begin
        q_obj0_pd1_shift <= d_obj0_pd1_shift;
        q_obj1_pd1_shift <= d_obj1_pd1_shift;
        q_obj2_pd1_shift <= d_obj2_pd1_shift;
        q_obj3_pd1_shift <= d_obj3_pd1_shift;
        q_obj4_pd1_shift <= d_obj4_pd1_shift;
        q_obj5_pd1_shift <= d_obj5_pd1_shift;
        q_obj6_pd1_shift <= d_obj6_pd1_shift;
        q_obj7_pd1_shift <= d_obj7_pd1_shift;
        q_obj0_pd0_shift <= d_obj0_pd0_shift;
        q_obj1_pd0_shift <= d_obj1_pd0_shift;
        q_obj2_pd0_shift <= d_obj2_pd0_shift;
        q_obj3_pd0_shift <= d_obj3_pd0_shift;
        q_obj4_pd0_shift <= d_obj4_pd0_shift;
        q_obj5_pd0_shift <= d_obj5_pd0_shift;
        q_obj6_pd0_shift <= d_obj6_pd0_shift;
        q_obj7_pd0_shift <= d_obj7_pd0_shift;
      end
  end

wire       sbm_rd_obj0_primary;
wire       sbm_rd_obj0_priority;
wire [1:0] sbm_rd_obj0_ps;
wire [7:0] sbm_rd_obj0_pd1;
wire [7:0] sbm_rd_obj0_pd0;
wire [7:0] sbm_rd_obj0_x;
wire       sbm_rd_obj1_primary;
wire       sbm_rd_obj1_priority;
wire [1:0] sbm_rd_obj1_ps;
wire [7:0] sbm_rd_obj1_pd1;
wire [7:0] sbm_rd_obj1_pd0;
wire [7:0] sbm_rd_obj1_x;
wire       sbm_rd_obj2_primary;
wire       sbm_rd_obj2_priority;
wire [1:0] sbm_rd_obj2_ps;
wire [7:0] sbm_rd_obj2_pd1;
wire [7:0] sbm_rd_obj2_pd0;
wire [7:0] sbm_rd_obj2_x;
wire       sbm_rd_obj3_primary;
wire       sbm_rd_obj3_priority;
wire [1:0] sbm_rd_obj3_ps;
wire [7:0] sbm_rd_obj3_pd1;
wire [7:0] sbm_rd_obj3_pd0;
wire [7:0] sbm_rd_obj3_x;
wire       sbm_rd_obj4_primary;
wire       sbm_rd_obj4_priority;
wire [1:0] sbm_rd_obj4_ps;
wire [7:0] sbm_rd_obj4_pd1;
wire [7:0] sbm_rd_obj4_pd0;
wire [7:0] sbm_rd_obj4_x;
wire       sbm_rd_obj5_primary;
wire       sbm_rd_obj5_priority;
wire [1:0] sbm_rd_obj5_ps;
wire [7:0] sbm_rd_obj5_pd1;
wire [7:0] sbm_rd_obj5_pd0;
wire [7:0] sbm_rd_obj5_x;
wire       sbm_rd_obj6_primary;
wire       sbm_rd_obj6_priority;
wire [1:0] sbm_rd_obj6_ps;
wire [7:0] sbm_rd_obj6_pd1;
wire [7:0] sbm_rd_obj6_pd0;
wire [7:0] sbm_rd_obj6_x;
wire       sbm_rd_obj7_primary;
wire       sbm_rd_obj7_priority;
wire [1:0] sbm_rd_obj7_ps;
wire [7:0] sbm_rd_obj7_pd1;
wire [7:0] sbm_rd_obj7_pd0;
wire [7:0] sbm_rd_obj7_x;


assign sbm_rd_obj0_primary  = m_sbm[0] >> 27;
assign sbm_rd_obj0_priority = m_sbm[0] >> 26;
assign sbm_rd_obj0_ps       = m_sbm[0] >> 24;
assign sbm_rd_obj0_pd1      = m_sbm[0] >> 16;
assign sbm_rd_obj0_pd0      = m_sbm[0] >> 8;
assign sbm_rd_obj0_x        = m_sbm[0];
assign sbm_rd_obj1_primary  = m_sbm[1] >> 27;
assign sbm_rd_obj1_priority = m_sbm[1] >> 26;
assign sbm_rd_obj1_ps       = m_sbm[1] >> 24;
assign sbm_rd_obj1_pd1      = m_sbm[1] >> 16;
assign sbm_rd_obj1_pd0      = m_sbm[1] >> 8;
assign sbm_rd_obj1_x        = m_sbm[1];
assign sbm_rd_obj2_primary  = m_sbm[2] >> 27;
assign sbm_rd_obj2_priority = m_sbm[2] >> 26;
assign sbm_rd_obj2_ps       = m_sbm[2] >> 24;
assign sbm_rd_obj2_pd1      = m_sbm[2] >> 16;
assign sbm_rd_obj2_pd0      = m_sbm[2] >> 8;
assign sbm_rd_obj2_x        = m_sbm[2];
assign sbm_rd_obj3_primary  = m_sbm[3] >> 27;
assign sbm_rd_obj3_priority = m_sbm[3] >> 26;
assign sbm_rd_obj3_ps       = m_sbm[3] >> 24;
assign sbm_rd_obj3_pd1      = m_sbm[3] >> 16;
assign sbm_rd_obj3_pd0      = m_sbm[3] >> 8;
assign sbm_rd_obj3_x        = m_sbm[3];
assign sbm_rd_obj4_primary  = m_sbm[4] >> 27;
assign sbm_rd_obj4_priority = m_sbm[4] >> 26;
assign sbm_rd_obj4_ps       = m_sbm[4] >> 24;
assign sbm_rd_obj4_pd1      = m_sbm[4] >> 16;
assign sbm_rd_obj4_pd0      = m_sbm[4] >> 8;
assign sbm_rd_obj4_x        = m_sbm[4];
assign sbm_rd_obj5_primary  = m_sbm[5] >> 27;
assign sbm_rd_obj5_priority = m_sbm[5] >> 26;
assign sbm_rd_obj5_ps       = m_sbm[5] >> 24;
assign sbm_rd_obj5_pd1      = m_sbm[5] >> 16;
assign sbm_rd_obj5_pd0      = m_sbm[5] >> 8;
assign sbm_rd_obj5_x        = m_sbm[5];
assign sbm_rd_obj6_primary  = m_sbm[6] >> 27;
assign sbm_rd_obj6_priority = m_sbm[6] >> 26;
assign sbm_rd_obj6_ps       = m_sbm[6] >> 24;
assign sbm_rd_obj6_pd1      = m_sbm[6] >> 16;
assign sbm_rd_obj6_pd0      = m_sbm[6] >> 8;
assign sbm_rd_obj6_x        = m_sbm[6];
assign sbm_rd_obj7_primary  = m_sbm[7] >> 27;
assign sbm_rd_obj7_priority = m_sbm[7] >> 26;
assign sbm_rd_obj7_ps       = m_sbm[7] >> 24;
assign sbm_rd_obj7_pd1      = m_sbm[7] >> 16;
assign sbm_rd_obj7_pd0      = m_sbm[7] >> 8;
assign sbm_rd_obj7_x        = m_sbm[7];

always @*
  begin
    d_obj0_pd1_shift = q_obj0_pd1_shift;
    d_obj1_pd1_shift = q_obj1_pd1_shift;
    d_obj2_pd1_shift = q_obj2_pd1_shift;
    d_obj3_pd1_shift = q_obj3_pd1_shift;
    d_obj4_pd1_shift = q_obj4_pd1_shift;
    d_obj5_pd1_shift = q_obj5_pd1_shift;
    d_obj6_pd1_shift = q_obj6_pd1_shift;
    d_obj7_pd1_shift = q_obj7_pd1_shift;
    d_obj0_pd0_shift = q_obj0_pd0_shift;
    d_obj1_pd0_shift = q_obj1_pd0_shift;
    d_obj2_pd0_shift = q_obj2_pd0_shift;
    d_obj3_pd0_shift = q_obj3_pd0_shift;
    d_obj4_pd0_shift = q_obj4_pd0_shift;
    d_obj5_pd0_shift = q_obj5_pd0_shift;
    d_obj6_pd0_shift = q_obj6_pd0_shift;
    d_obj7_pd0_shift = q_obj7_pd0_shift;

    if (ri_spr_en && (vga_nes_x < 239))
      begin
        if (pix_pulse_in)
          begin
            d_obj0_pd1_shift = { 1'b0, q_obj0_pd1_shift[7:1] };
            d_obj0_pd0_shift = { 1'b0, q_obj0_pd0_shift[7:1] };
          end
        else if ((vga_nes_x - sbm_rd_obj0_x) == 8'h00)
          begin
            d_obj0_pd1_shift = sbm_rd_obj0_pd1;
            d_obj0_pd0_shift = sbm_rd_obj0_pd0;
          end

        if (pix_pulse_in)
          begin
            d_obj1_pd1_shift = { 1'b0, q_obj1_pd1_shift[7:1] };
            d_obj1_pd0_shift = { 1'b0, q_obj1_pd0_shift[7:1] };
          end
        else if ((vga_nes_x - sbm_rd_obj1_x) == 8'h00)
          begin
            d_obj1_pd1_shift = sbm_rd_obj1_pd1;
            d_obj1_pd0_shift = sbm_rd_obj1_pd0;
          end

        if (pix_pulse_in)
          begin
            d_obj2_pd1_shift = { 1'b0, q_obj2_pd1_shift[7:1] };
            d_obj2_pd0_shift = { 1'b0, q_obj2_pd0_shift[7:1] };
          end
        else if ((vga_nes_x - sbm_rd_obj2_x) == 8'h00)
          begin
            d_obj2_pd1_shift = sbm_rd_obj2_pd1;
            d_obj2_pd0_shift = sbm_rd_obj2_pd0;
          end

        if (pix_pulse_in)
          begin
            d_obj3_pd1_shift = { 1'b0, q_obj3_pd1_shift[7:1] };
            d_obj3_pd0_shift = { 1'b0, q_obj3_pd0_shift[7:1] };
          end
        else if ((vga_nes_x - sbm_rd_obj3_x) == 8'h00)
          begin
            d_obj3_pd1_shift = sbm_rd_obj3_pd1;
            d_obj3_pd0_shift = sbm_rd_obj3_pd0;
          end

        if (pix_pulse_in)
          begin
            d_obj4_pd1_shift = { 1'b0, q_obj4_pd1_shift[7:1] };
            d_obj4_pd0_shift = { 1'b0, q_obj4_pd0_shift[7:1] };
          end
        else if ((vga_nes_x - sbm_rd_obj4_x) == 8'h00)
          begin
            d_obj4_pd1_shift = sbm_rd_obj4_pd1;
            d_obj4_pd0_shift = sbm_rd_obj4_pd0;
          end

        if (pix_pulse_in)
          begin
            d_obj5_pd1_shift = { 1'b0, q_obj5_pd1_shift[7:1] };
            d_obj5_pd0_shift = { 1'b0, q_obj5_pd0_shift[7:1] };
          end
        else if ((vga_nes_x - sbm_rd_obj5_x) == 8'h00)
          begin
            d_obj5_pd1_shift = sbm_rd_obj5_pd1;
            d_obj5_pd0_shift = sbm_rd_obj5_pd0;
          end

        if (pix_pulse_in)
          begin
            d_obj6_pd1_shift = { 1'b0, q_obj6_pd1_shift[7:1] };
            d_obj6_pd0_shift = { 1'b0, q_obj6_pd0_shift[7:1] };
          end
        else if ((vga_nes_x - sbm_rd_obj6_x) == 8'h00)
          begin
            d_obj6_pd1_shift = sbm_rd_obj6_pd1;
            d_obj6_pd0_shift = sbm_rd_obj6_pd0;
          end

        if (pix_pulse_in)
          begin
            d_obj7_pd1_shift = { 1'b0, q_obj7_pd1_shift[7:1] };
            d_obj7_pd0_shift = { 1'b0, q_obj7_pd0_shift[7:1] };
          end
        else if ((vga_nes_x - sbm_rd_obj7_x) == 8'h00)
          begin
            d_obj7_pd1_shift = sbm_rd_obj7_pd1;
            d_obj7_pd0_shift = sbm_rd_obj7_pd0;
          end
      end
  end

assign { spr_primary, spr_priority, palette_idx_out } =
  (!ri_spr_en || (ri_spr_ls_clip && (vga_nes_x >= 10'h000) && (vga_nes_x < 10'h008))) ?
      6'h00 :
  ({ q_obj0_pd1_shift[0], q_obj0_pd0_shift[0] } != 0) ?
      { sbm_rd_obj0_primary, sbm_rd_obj0_priority, sbm_rd_obj0_ps, q_obj0_pd1_shift[0], q_obj0_pd0_shift[0] } :
  ({ q_obj1_pd1_shift[0], q_obj1_pd0_shift[0] } != 0) ?
      { sbm_rd_obj1_primary, sbm_rd_obj1_priority, sbm_rd_obj1_ps, q_obj1_pd1_shift[0], q_obj1_pd0_shift[0] } :
  ({ q_obj2_pd1_shift[0], q_obj2_pd0_shift[0] } != 0) ?
      { sbm_rd_obj2_primary, sbm_rd_obj2_priority, sbm_rd_obj2_ps, q_obj2_pd1_shift[0], q_obj2_pd0_shift[0] } :
  ({ q_obj3_pd1_shift[0], q_obj3_pd0_shift[0] } != 0) ?
      { sbm_rd_obj3_primary, sbm_rd_obj3_priority, sbm_rd_obj3_ps, q_obj3_pd1_shift[0], q_obj3_pd0_shift[0] } :
  ({ q_obj4_pd1_shift[0], q_obj4_pd0_shift[0] } != 0) ?
      { sbm_rd_obj4_primary, sbm_rd_obj4_priority, sbm_rd_obj4_ps, q_obj4_pd1_shift[0], q_obj4_pd0_shift[0] } :
  ({ q_obj5_pd1_shift[0], q_obj5_pd0_shift[0] } != 0) ?
      { sbm_rd_obj5_primary, sbm_rd_obj5_priority, sbm_rd_obj5_ps, q_obj5_pd1_shift[0], q_obj5_pd0_shift[0] } :
  ({ q_obj6_pd1_shift[0], q_obj6_pd0_shift[0] } != 0) ?
      { sbm_rd_obj6_primary, sbm_rd_obj6_priority, sbm_rd_obj6_ps, q_obj6_pd1_shift[0], q_obj6_pd0_shift[0] } :
  ({ q_obj7_pd1_shift[0], q_obj7_pd0_shift[0] } != 0) ?
      { sbm_rd_obj7_primary, sbm_rd_obj7_priority, sbm_rd_obj7_ps, q_obj7_pd1_shift[0], q_obj7_pd0_shift[0] } : 6'b0000;

assign ri_spr_ram_din    = m_oam[ri_spr_ram_a];
assign ri_spr_overflow = q_spr_overflow;


//
// Vidmem interface.
//
reg  [5:0] palette_ram [31:0];  // internal palette RAM.  32 entries, 6-bits per entry.

`define PRAM_A(addr) ((addr & 5'h03) ? addr :  (addr & 5'h0f))

always @(posedge clk_in)
  begin
    if (rst_in)
      begin
        palette_ram[`PRAM_A(5'h00)] <= 6'h09;
        palette_ram[`PRAM_A(5'h01)] <= 6'h01;
        palette_ram[`PRAM_A(5'h02)] <= 6'h00;
        palette_ram[`PRAM_A(5'h03)] <= 6'h01;
        palette_ram[`PRAM_A(5'h04)] <= 6'h00;
        palette_ram[`PRAM_A(5'h05)] <= 6'h02;
        palette_ram[`PRAM_A(5'h06)] <= 6'h02;
        palette_ram[`PRAM_A(5'h07)] <= 6'h0d;
        palette_ram[`PRAM_A(5'h08)] <= 6'h08;
        palette_ram[`PRAM_A(5'h09)] <= 6'h10;
        palette_ram[`PRAM_A(5'h0a)] <= 6'h08;
        palette_ram[`PRAM_A(5'h0b)] <= 6'h24;
        palette_ram[`PRAM_A(5'h0c)] <= 6'h00;
        palette_ram[`PRAM_A(5'h0d)] <= 6'h00;
        palette_ram[`PRAM_A(5'h0e)] <= 6'h04;
        palette_ram[`PRAM_A(5'h0f)] <= 6'h2c;
        palette_ram[`PRAM_A(5'h11)] <= 6'h01;
        palette_ram[`PRAM_A(5'h12)] <= 6'h34;
        palette_ram[`PRAM_A(5'h13)] <= 6'h03;
        palette_ram[`PRAM_A(5'h15)] <= 6'h04;
        palette_ram[`PRAM_A(5'h16)] <= 6'h00;
        palette_ram[`PRAM_A(5'h17)] <= 6'h14;
        palette_ram[`PRAM_A(5'h19)] <= 6'h3a;
        palette_ram[`PRAM_A(5'h1a)] <= 6'h00;
        palette_ram[`PRAM_A(5'h1b)] <= 6'h02;
        palette_ram[`PRAM_A(5'h1d)] <= 6'h20;
        palette_ram[`PRAM_A(5'h1e)] <= 6'h2c;
        palette_ram[`PRAM_A(5'h1f)] <= 6'h08;
      end
    else if (ri_pram_wr)
      palette_ram[`PRAM_A(vram_a_out[4:0])] <= ri_vram_dout[5:0];
  end

assign ri_vram_din = vram_d_in;
assign ri_pram_din = palette_ram[`PRAM_A(vram_a_out[4:0])];

assign vram_a_out  = (spr_vram_req) ? spr_vram_a : bg_vram_a;
assign vram_d_out  = ri_vram_dout;
assign vram_wr_out = ri_vram_wr;

//
// Multiplexer.  Final system palette index derivation.
//
reg  q_pri_obj_col;
wire d_pri_obj_col;

always @(posedge clk_in)
  begin
    if (rst_in)
      q_pri_obj_col <= 1'b0;
    else
      q_pri_obj_col <= d_pri_obj_col;
  end

wire spr_foreground;
wire spr_trans;
wire bg_trans;

assign spr_foreground  = ~spr_priority;
assign spr_trans       = ~|spr_palette_idx[1:0];
assign bg_trans        = ~|bg_palette_idx[1:0];

assign d_pri_obj_col = (vga_nes_y_next == 0)                    ? 1'b0 :
                       (spr_primary && !spr_trans && !bg_trans) ? 1'b1 : q_pri_obj_col;

assign vga_sys_palette_idx =
  ((spr_foreground || bg_trans) && !spr_trans) ? palette_ram[{ 1'b1, spr_palette_idx }] :
  (!bg_trans)                                  ? palette_ram[{ 1'b0, bg_palette_idx }]  :
                                                 palette_ram[5'h00];

assign ri_spr_pri_col = q_pri_obj_col;

//
// Assign miscellaneous output signals.
//
assign nvbl_out = ~(ri_vblank & ri_nvbl_en);

endmodule
