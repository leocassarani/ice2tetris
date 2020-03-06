`default_nettype none
`timescale 1ns / 1ps

module Computer (
  input CLK,
  input BTN1, BTN2, BTN3,
  input FLASH_IO1,
  output LEDR_N,
  output P1A1, P1A2, P1A3, P1A4, P1A7, P1A8, P1A9, P1A10,
  output FLASH_SCK, FLASH_SSB, FLASH_IO0,
);

wire pll_out, pll_locked;
wire reset = !pll_locked;

wire [15:0] pc;
wire [15:0] instr;
wire [15:0] mem_in;
wire [15:0] mem_out;
wire [14:0] mem_addr;
wire mem_write;
wire rom_ready;

assign LEDR_N = !rom_ready;

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

ROM rom (
  .clk(pll_out),
  .reset(reset),
  .address(pc),
  .instruction(instr),
  .ready(rom_ready),

  .spi_cs(FLASH_SSB),
  .spi_sclk(FLASH_SCK),
  .spi_mosi(FLASH_IO0),
  .spi_miso(FLASH_IO1),
);

Memory memory (
  .clk(pll_out),
  .in(mem_out),
  .load(mem_write),
  .address(mem_addr),
  .out(mem_in),
  .keyboard_buttons({ BTN3, BTN2, BTN1 }),
  .seven_segment({ P1A10, P1A9, P1A8, P1A7, P1A4, P1A3, P1A2, P1A1 }),
);

CPU cpu (
  .clk(pll_out),
  .reset(!rom_ready),
  .instruction(instr),
  .memory_in(mem_in),
  .memory_out(mem_out),
  .memory_write(mem_write),
  .memory_address(mem_addr),
  .pc(pc),
);

endmodule
