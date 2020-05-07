`default_nettype none

module computer (
  input CLK,
  input BTN_N, BTN1, BTN2, BTN3,
  input FLASH_IO1,
  output LEDG_N,
  output P1A1, P1A2, P1A3, P1A4, P1A7, P1A8, P1A9, P1A10,
  output P1B1, P1B2, P1B3, P1B4, P1B7, P1B8,
  output FLASH_SCK, FLASH_SSB, FLASH_IO0,
);

wire clk_out, clk_locked;
wire rom_ready;

wire [15:0] rom_address;
wire [15:0] instruction;
wire [15:0] mem_address, mem_rdata, mem_wdata;
wire mem_busy, mem_load;

wire reset = !rom_ready || !BTN_N;
assign LEDG_N = !rom_ready;

clock clock (
  .refclk(CLK),
  .locked(clk_locked),
  .out(clk_out),
);

cpu cpu (
  .clk(clk_out),
  .reset(reset),
  .instruction(instruction),
  .prog_counter(rom_address),
  .mem_busy(mem_busy),
  .mem_rdata(mem_rdata),
  .mem_wdata(mem_wdata),
  .mem_load(mem_load),
  .mem_address(mem_address),
);

memory memory (
  .clk(clk_out),
  .address(mem_address),
  .load(mem_load),
  .in(mem_wdata),
  .out(mem_rdata),
  .busy(mem_busy),

  .vga_h_sync(P1B7),
  .vga_v_sync(P1B8),
  .vga_red({ P1A4, P1A3, P1A2, P1A1 }),
  .vga_blue({ P1A10, P1A9, P1A8, P1A7 }),
  .vga_green({ P1B4, P1B3, P1B2, P1B1 }),

  .kbd_buttons({ BTN3, BTN2, BTN1 }),
);

rom rom (
  .clk(clk_out),
  .clken(clk_locked),
  .ready(rom_ready),
  .address(rom_address),
  .instruction(instruction),

  .spi_cs(FLASH_SSB),
  .spi_sclk(FLASH_SCK),
  .spi_mosi(FLASH_IO0),
  .spi_miso(FLASH_IO1),
);

endmodule