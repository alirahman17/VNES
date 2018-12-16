`timescale 1ns / 1ps


module fifo
#(
  parameter DATA_BITS = 8,
  parameter ADDR_BITS = 3
)
(
  input  wire clk,      // 50MHz clock signal
  input  wire reset,    
  input  wire pop_en,    // Pop enable
  input  wire push_en,    // Push enable 
  input  wire [DATA_BITS-1:0] push_data,  // Data to be pushitten on push_en
  output wire [DATA_BITS-1:0] pop_data,  // start of FIFO
  output wire full,     // FIFO is full signal
  output wire empty     // FIFO is empty signal
);

reg  [ADDR_BITS-1:0] q_pop_ptr;
wire [ADDR_BITS-1:0] d_pop_ptr;
reg  [ADDR_BITS-1:0] q_push_ptr;
wire [ADDR_BITS-1:0] d_push_ptr;
reg  q_empty;
wire d_empty;
reg  q_full;
wire d_full;

reg  [DATA_BITS-1:0] q_data_array [2**ADDR_BITS-1:0];
wire [DATA_BITS-1:0] d_data;

wire pop_en_prot;
wire push_en_prot;

// FF update logic.  Synchronous reset.
always @(posedge clk)
  begin
    if (reset)
      begin
        q_pop_ptr <= 0;
        q_push_ptr <= 0;
        q_empty <= 1'b1;
        q_full <= 1'b0;
      end
    else
      begin
        q_pop_ptr <= d_pop_ptr;
        q_push_ptr <= d_push_ptr;
        q_empty <= d_empty;
        q_full <= d_full;
        q_data_array[q_push_ptr] <= d_data;
      end
  end

// protected push/pop signals.
assign pop_en_prot = (pop_en && !q_empty);
assign push_en_prot = (push_en && !q_full);

// push
assign d_push_ptr = (push_en_prot)  ? q_push_ptr + 1'h1 : q_push_ptr;
assign d_data   = (push_en_prot)  ? push_data         : q_data_array[q_push_ptr];

// pop
assign d_pop_ptr = (pop_en_prot)  ? q_pop_ptr + 1'h1 : q_pop_ptr;

wire [ADDR_BITS-1:0] addr_bits_wide_1;
assign addr_bits_wide_1 = 1;

// Detect empty fifo

assign d_empty = ((q_empty && !push_en_prot)||(((q_push_ptr - q_pop_ptr) == addr_bits_wide_1) && pop_en_prot));

// Detect full fifo
assign d_full  = ((q_full && !pop_en_prot)||(((q_pop_ptr - q_push_ptr) == addr_bits_wide_1) && push_en_prot));


// Assign outputs to FFs.
assign pop_data = q_data_array[q_pop_ptr];
assign full    = q_full;
assign empty   = q_empty;

endmodule
