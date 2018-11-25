`timescale 1ns / 1ps

module controller
(
    input wire clk,
    input wire reset,
    input wire write_en,
    input wire [15:0] addr,
    input wire data_in,
    input wire ctrlr_in_1,
    input wire ctrlr_in_2,
    output wire ctrlr_clk,
    output wire ctrlr_latch,
    output reg [7:0] data_out
);

reg [7:0] q_ctrlr1_state;
reg [7:0] d_ctrlr1_state;
reg [7:0] q_ctrlr2_state;
reg [7:0] d_ctrlr2_state;
reg       q_ctrlr_clk;
reg [7:0] d_ctrlr_clk;
reg       q_ctrlr_latch;
reg       d_ctrlr_latch;
reg [8:0] q_count;
reg [8:0] d_count;

wire [2:0] state_index;

always @(posedge clk)
    begin
        if(reset)
            begin
                q_ctrlr1_state <= 8'h00;
                q_ctrlr2_state <= 8'h00;
                q_ctrlr_clk <= 1'b0;
                q_ctrlr_latch <= 1'b0;
                q_count <= 9'h00;
            end
        else
            begin
                q_ctrlr1_state <= d_ctrlr1_state;
                q_ctrlr2_state <= d_ctrlr2_state;
                q_ctrlr_clk    <= d_ctrlr_clk;
                q_ctrlr_latch  <= d_ctrlr_latch;
                q_count <= d_count;
            end
    end

always@(*)
begin

    d_ctrlr1_state = q_ctrlr1_state;
    d_ctrlr2_state = q_ctrlr2_state;
    d_ctrlr_clk    = q_ctrlr_clk;
    d_ctrlr_latch  = q_ctrlr_latch;

    d_count = q_count + 9'h001;

    if (q_count[5:1] == 5'h00)
      begin
        d_ctrlr1_state[state_index] = ~ctrlr_in_1;
        d_ctrlr2_state[state_index] = ~ctrlr_in_2;

        if (q_count[8:1] == 8'h00)
          d_ctrlr_latch = 1'b1;
        else
          d_ctrlr_clk = 1'b1;
      end
    else if (q_count[5:1] == 5'h10)
      begin
        d_ctrlr_clk   = 1'b0;
        d_ctrlr_latch = 1'b0;
      end
  end

assign state_index = q_count[8:6] - 3'h1;
assign ctrlr_latch  = q_ctrlr_latch;
assign ctrlr_clk    = q_ctrlr_clk;

localparam [15:0] CTRLR1_MMR_ADDR = 16'h4016;
localparam [15:0] CTRLR2_MMR_ADDR = 16'h4017;

localparam S_STROBE_WROTE_0 = 1'b0,
           S_STROBE_WROTE_1 = 1'b1;


reg [15:0]q_addr;
reg [8:0] q_ctrlr1_read_state;
reg [8:0] d_ctrlr1_read_state;
reg [8:0] q_ctrlr2_read_state;
reg [8:0] d_ctrlr2_read_state;
reg q_strobe_state;
reg d_strobe_state;

always @(posedge clk)
  begin
    if (reset)
      begin
        q_addr           <= 16'h0000;
        q_ctrlr1_read_state <= 9'h000;
        q_ctrlr2_read_state <= 9'h000;
        q_strobe_state   <= S_STROBE_WROTE_0;
      end
    else
      begin
        q_addr           <= addr;
        q_ctrlr1_read_state <= d_ctrlr1_read_state;
        q_ctrlr2_read_state <= d_ctrlr2_read_state;
        q_strobe_state   <= d_strobe_state;
      end
  end

always @(*)
  begin
    data_out = 8'h00;

    d_ctrlr1_read_state = q_ctrlr1_read_state;
    d_ctrlr2_read_state = q_ctrlr2_read_state;
    d_strobe_state   = q_strobe_state;

    if (addr[15:1] == CTRLR1_MMR_ADDR[15:1])
      begin
        data_out = { 7'h00, ((addr[0]) ? q_ctrlr2_read_state[0] : q_ctrlr1_read_state[0]) };

        
        if (addr != q_addr)
          begin
            // App must write 0x4016 to 1 then to 0 in order to reset and begin reading the controller
            // state.
            if (write_en && !addr[0])
              begin
                if ((q_strobe_state == S_STROBE_WROTE_0) && (data_out == 1'b1))
                  begin
                    d_strobe_state = S_STROBE_WROTE_1;
                  end
                else if ((q_strobe_state == S_STROBE_WROTE_1) && (data_in == 1'b0))
                  begin
                    d_strobe_state = S_STROBE_WROTE_0;
                    d_ctrlr1_read_state = { q_ctrlr1_state, 1'b0 };
                    d_ctrlr2_read_state = { q_ctrlr2_state, 1'b0 };
                  end
              end

            else if (!write_en && !addr[0])
              d_ctrlr1_read_state = { 1'b1, q_ctrlr1_read_state[8:1] };
            else if (!write_en && addr[0])
              d_ctrlr2_read_state = { 1'b1, q_ctrlr2_read_state[8:1] };
          end
      end
end


endmodule
