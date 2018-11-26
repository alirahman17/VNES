module vga(input wire clk, input wire i_pix_stb, input wire i_rst,         
            output wire horizSync, output wire vertSync, output wire o_blanking,
            output wire o_active, output wire o_screenend, output wire o_animate,
            output wire [9:0] o_x, output wire [8:0] o_y);

    localparam HS_STA = 16;
    localparam HS_END = 16 + 96;
    localparam HA_STA = 16 + 96 + 48;
    localparam VS_STA = 480 + 11;
    localparam VS_END = 480 + 11 + 2;
    localparam VA_END = 480;
    localparam LINE   = 800;
    localparam SCREEN = 524;

    reg [9:0] HorizCount;
    reg [9:0] vertCount;

    assign horizSync = ~((HorizCount >= HS_STA) & (HorizCount < HS_END));
    assign vertSync = ~((vertCount >= VS_STA) & (vertCount < VS_END));
    assign o_x = (HorizCount < HA_STA) ? 0 : (HorizCount - HA_STA);
    assign o_y = (vertCount >= VA_END) ? (VA_END - 1) : (vertCount);
    assign o_blanking = ((HorizCount < HA_STA) | (vertCount > VA_END - 1));
    assign o_active = ~((HorizCount < HA_STA) | (vertCount > VA_END - 1));
    assign o_screenend = ((vertCount == SCREEN - 1) & (HorizCount == LINE));
    assign o_animate = ((vertCount == VA_END - 1) & (HorizCount == LINE));

    always @ (posedge clk)
    begin
        if (i_rst)
        begin
            HorizCount <= 0;
            vertCount <= 0;
        end
        if (i_pix_stb)
        begin
            if (HorizCount == LINE)
            begin
                HorizCount <= 0;
                vertCount <= vertCount + 1;
            end
            else
                HorizCount <= HorizCount + 1;
            if (vertCount == SCREEN)
                vertCount <= 0;
        end
    end
endmodule
