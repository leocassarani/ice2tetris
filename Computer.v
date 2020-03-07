`default_nettype none

module Computer (
  input CLK,
  input FLASH_IO1,
  output LEDR_N, LEDG_N,
  output P1A1, P1A2, P1A3, P1A4, P1A7, P1A8, P1A9, P1A10,
  output P1B1, P1B2, P1B3, P1B4, P1B7, P1B8, P1B9, P1B10,
  output FLASH_SCK, FLASH_SSB, FLASH_IO0,
);

wire clk_out, clk_locked;
wire reset = !clk_locked;
wire rom_ready;
wire [15:0] instruction;

assign LEDR_N = !clk_locked;
assign LEDG_N = !rom_ready;

Clock clock (
  .refclk(CLK),
  .locked(clk_locked),
  .out(clk_out),
);

ROM rom (
  .clk(clk_out),
  .reset(reset),
  .ready(rom_ready),
  .address(16'b0),
  .instruction(instruction),
  .spi_cs(FLASH_SSB),
  .spi_sclk(FLASH_SCK),
  .spi_mosi(FLASH_IO0),
  .spi_miso(FLASH_IO1),
);

Screen screen (
  .clk(clk_out),
  .din(instruction),
  .dout_lo({ P1A10, P1A9, P1A8, P1A7, P1A4, P1A3, P1A2, P1A1 }),
  .dout_hi({ P1B10, P1B9, P1B8, P1B7, P1B4, P1B3, P1B2, P1B1 }),
);

endmodule
