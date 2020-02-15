module Computer (
  input CLK,
  output P1A1, P1A2, P1A3, P1A4, P1A7, P1A8, P1A9, P1A10,
  output P1B1, P1B2, P1B3, P1B4, P1B7, P1B8,
);

wire clk_out;

reg [9:0] h_line, v_line;

wire display = h_line < 640 && v_line < 480;
wire h_sync = h_line < 656 || h_line >= 752;
wire v_sync = v_line < 490 || v_line >= 492;

wire [3:0] red = { P1A4, P1A3, P1A2, P1A1 };
wire [3:0] blue = { P1A10, P1A9, P1A8, P1A7 };
wire [3:0] green = { P1B4, P1B3, P1B2, P1B1 };

wire box = h_line >= 64 && h_line < 576 && v_line >= 112 && v_line < 368;
wire [3:0] fill = { box, box, box, box };

assign red = fill;
assign blue = fill;
assign green = fill;

assign P1B7 = h_sync;
assign P1B8 = v_sync;

SB_PLL40_PAD #(
  .FEEDBACK_PATH("SIMPLE"),
  .DIVR(4'b0000),        // DIVR = 0
  .DIVF(7'b1000010),     // DIVF = 66
  .DIVQ(3'b101),         // DIVQ = 5
  .FILTER_RANGE(3'b001), // FILTER_RANGE = 1
) pll_clock (
  .RESETB(1'b1),
  .BYPASS(1'b0),
  .PACKAGEPIN(CLK),
  .PLLOUTCORE(clk_out),
);

always @(posedge clk_out) begin
  if (h_line == 799) begin
    h_line <= 0;

    if (v_line == 524) begin
      v_line <= 0;
    end else begin
      v_line <= v_line + 1;
    end
  end else begin
    h_line <= h_line + 1;
  end
end

endmodule
