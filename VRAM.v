module VRAM (
  input clk,
  input reset,
  input rden,
  input [13:0] raddr,

  output loaded,
  output [15:0] out,

  input spi_miso,
  output spi_cs, output spi_sclk, output spi_mosi,
);

reg [15:0] waddr = 0;

wire loading = waddr < 16'h4000;
assign loaded = !loading;

wire ram_write = !reset && loading && rom_ready;

wire rom_ready;
wire [15:0] rom_out;

wire [15:0] ram_out;
assign out = rden ? ram_out : 16'h0000;

ROM rom (
  .clk(clk),
  .reset(reset),
  .address(waddr),
  .out(rom_out),
  .ready(rom_ready),

  .spi_cs(spi_cs),
  .spi_sclk(spi_sclk),
  .spi_mosi(spi_mosi),
  .spi_miso(spi_miso),
);

SB_SPRAM256KA spram (
  .CLOCK(clk),
  .CHIPSELECT(1'b1),
  .ADDRESS(loading ? waddr[13:0] : raddr),
  .WREN(ram_write),
  .MASKWREN(4'b1111),
  .DATAIN(loading ? rom_out : 16'b0),
  .STANDBY(1'b0),
  .SLEEP(1'b0),
  .POWEROFF(1'b1),
  .DATAOUT(ram_out),
);

always @(posedge clk) begin
  if (ram_write) begin
    waddr <= waddr + 1;
  end
end

endmodule
