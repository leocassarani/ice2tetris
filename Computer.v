`timescale 1ns / 1ps

module Computer (
  input CLK, BTN_N, FLASH_IO1,
  output LEDR_N, LEDG_N,
  output P1A1, P1A2, P1A3, P1A4, P1A7, P1A8, P1A9, P1A10,
  output FLASH_SCK, FLASH_SSB, FLASH_IO0,
);

reg [23:0] clkdiv = 0;
reg clkdiv_pulse = 0;
reg flash = 0;

always @(posedge CLK) begin
  if (clkdiv == 12000000) begin
    clkdiv <= 0;
    clkdiv_pulse <= 1;
  end else begin
    clkdiv <= clkdiv + 1;
    clkdiv_pulse <= 0;
  end
end

always @(posedge clkdiv_pulse) begin
  flash <= ~flash;
end

assign LEDR_N = flash;
assign LEDG_N = !flash;

wire [14:0] addr;
wire [15:0] instr;

ROM rom (
  .clk(CLK),
  .address(addr),
  .instruction(instr),

  .spi_cs(FLASH_SSB),
  .spi_sclk(FLASH_SCK),
  .spi_mosi(FLASH_IO0),
  .spi_miso(FLASH_IO1),
);

CPU cpu (
  .clk(clkdiv_pulse),
  .reset(!BTN_N),
  .pc(addr),
);

Screen screen (
  .clk(CLK),
  .value(instr[7:0]),
  .seven_segment({ P1A10, P1A9, P1A8, P1A7, P1A4, P1A3, P1A2, P1A1 }),
);

endmodule
