`default_nettype none

module Computer (
  input CLK,
  input FLASH_IO1,
  input BTN1,
  output LEDR_N,
  output P1A1, P1A2, P1A3, P1A4, P1A7, P1A8, P1A9, P1A10,
  output P1B1, P1B2, P1B3, P1B4, P1B7, P1B8, P1B9, P1B10,
  output FLASH_SCK, FLASH_SSB, FLASH_IO0,
);

wire clk_out;

wire vram_ready;
assign LEDR_N = !vram_ready;

reg [13:0] vram_raddr = 0;
wire [15:0] vram_rdata;

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

VRAM vram (
  .clk(clk_out),
  .raddr(vram_raddr),
  .out(vram_rdata),
  .loaded(vram_ready),

  .spi_cs(FLASH_SSB),
  .spi_sclk(FLASH_SCK),
  .spi_mosi(FLASH_IO0),
  .spi_miso(FLASH_IO1),
);

seven_seg_ctrl seven_segment_top (
  .clk(clk_out),
  .din(vram_rdata[15:8]),
  .dout({ P1A10, P1A9, P1A8, P1A7, P1A4, P1A3, P1A2, P1A1 }),
);

seven_seg_ctrl seven_segment_bottom (
  .clk(clk_out),
  .din(vram_raddr[7:0]),
  .dout({ P1B10, P1B9, P1B8, P1B7, P1B4, P1B3, P1B2, P1B1 }),
);

always @(posedge BTN1) begin
  vram_raddr <= vram_raddr + 1;
end

endmodule
