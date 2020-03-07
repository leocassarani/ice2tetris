`default_nettype none

module computer (
  input CLK,
  input FLASH_IO1,
  output LEDR_N, LEDG_N,
  output FLASH_SCK, FLASH_SSB, FLASH_IO0,
);

wire clk_out, clk_locked;
wire reset = !clk_locked;
wire rom_ready;

assign LEDR_N = !clk_locked;
assign LEDG_N = !rom_ready;

clock clock (
  .refclk(CLK),
  .locked(clk_locked),
  .out(clk_out),
);

rom rom (
  .clk(clk_out),
  .reset(reset),
  .ready(rom_ready),
  .spi_cs(FLASH_SSB),
  .spi_sclk(FLASH_SCK),
  .spi_mosi(FLASH_IO0),
  .spi_miso(FLASH_IO1),
);

endmodule
