module rp2a03
(
  input  wire        clk_in,         // system clock
  input  wire        rst_in,         // system reset

  // CPU signals.
  input  wire        rdy_in,         // ready signal
  input  wire [ 7:0] d_in,           // data input bus
  input  wire        nnmi_in,        // /nmi interrupt signal (active low)
  input  wire        nres_in,        // /res interrupt signal (active low)
  output wire [ 7:0] d_out,          // data output bus
  output wire [15:0] a_out,          // address bus
  output wire        r_nw_out,       // read/write select (write low)
  output wire        brk_out,        // debug break signal

  // Joypad signals.
  input  wire        jp_data1_in,    // joypad 1 input signal
  input  wire        jp_data2_in,    // joypad 2 input signal
  output wire        jp_clk,         // joypad output clk signal
  output wire        jp_latch,       // joypad output latch signal

  // Audio signals.
  input  wire [ 3:0] mute_in,        // disable autio channels
  output wire        audio_out,      // pwm audio output

  // HCI interface.
  input  wire [ 3:0] dbgreg_sel_in,  // dbg reg select
  input  wire [ 7:0] dbgreg_d_in,    // dbg reg data in
  input  wire        dbgreg_wr_in,   // dbg reg write select
  output wire [ 7:0] dbgreg_d_out    // dbg reg data out
);

//
// CPU: central processing unit block.
//
wire        cpu_ready;
wire [ 7:0] cpu_din;
wire        cpu_nirq;
wire [ 7:0] cpu_dout;
wire [15:0] cpu_a;
wire        cpu_r_nw;

cpu cpu_blk(
  .clk_in(clk_in),
  .rst_in(rst_in),
  .ready_in(cpu_ready),
  .dbgreg_sel_in(dbgreg_sel_in),
  .dbgreg_in(dbgreg_d_in),
  .dbgreg_wr_in(dbgreg_wr_in),
  .d_in(cpu_din),
  .nnmi_in(nnmi_in),
  .nres_in(nres_in),
  .nirq_in(cpu_nirq),
  .d_out(cpu_dout),
  .a_out(cpu_a),
  .r_nw_out(cpu_r_nw),
  .brk_out(brk_out),
  .dbgreg_out(dbgreg_d_out)
);

//
// JP: joypad controller block.
//
wire [7:0] jp_dout;

controller jp_blk(
  .clk(clk_in),
  .reset(rst_in),
  .write_en(~cpu_r_nw),
  .addr(cpu_a),
  .data_in(cpu_dout[0]),
  .ctrlr_in_1(jp_data1_in),
  .ctrlr_in_2(jp_data2_in),
  .ctrlr_clk(jp_clk),
  .ctrlr_latch(jp_latch),
  .data_out(jp_dout)
);

//
// SPRDMA: sprite dma controller block.
//
wire        sprdma_active;
wire [15:0] sprdma_a;
wire [ 7:0] sprdma_dout;
wire        sprdma_r_nw;

sprdma sprdma_blk(
  .clk_in(clk_in),
  .rst_in(rst_in),
  .cpumc_a_in(cpu_a),
  .cpumc_din_in(cpu_dout),
  .cpumc_dout_in(cpu_din),
  .cpu_r_nw_in(cpu_r_nw),
  .active_out(sprdma_active),
  .cpumc_a_out(sprdma_a),
  .cpumc_d_out(sprdma_dout),
  .cpumc_r_nw_out(sprdma_r_nw)
);

assign cpu_ready = rdy_in & !sprdma_active;
assign cpu_din   = d_in | jp_dout;
assign cpu_nirq  = 1'b1;

assign d_out     = (sprdma_active) ? sprdma_dout : cpu_dout;
assign a_out     = (sprdma_active) ? sprdma_a    : cpu_a;
assign r_nw_out  = (sprdma_active) ? sprdma_r_nw : cpu_r_nw;

endmodule

