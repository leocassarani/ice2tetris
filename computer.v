`default_nettype none

module computer (
  input CLK,
  input FLASH_IO1,
  output LEDR_N, LEDG_N,
  output FLASH_SCK, FLASH_SSB, FLASH_IO0,
);

wire pll_out, pll_locked;
wire reset = !pll_locked;
wire rom_ready;

assign LEDR_N = !pll_locked;
assign LEDG_N = !rom_ready;

SB_PLL40_PAD #(
  .FEEDBACK_PATH("SIMPLE"),
  .DIVR(4'b0000),        // DIVR = 0
  .DIVF(7'b1000010),     // DIVF = 66
  .DIVQ(3'b101),         // DIVQ = 5
  .FILTER_RANGE(3'b001), // FILTER_RANGE = 1
) pll_clock (
  .RESETB(1'b1),
  .BYPASS(1'b0),
  .LOCK(pll_locked),
  .PACKAGEPIN(CLK),
  .PLLOUTGLOBAL(pll_out),
);

rom rom (
  .clk(pll_out),
  .reset(reset),
  .ready(rom_ready),
  .spi_cs(FLASH_SSB),
  .spi_sclk(FLASH_SCK),
  .spi_mosi(FLASH_IO0),
  .spi_miso(FLASH_IO1),
);

endmodule
