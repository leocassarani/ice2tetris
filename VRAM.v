module VRAM (
  input clk,
  input [13:0] raddr,

  output loaded,
  output [15:0] out,

  input spi_miso,
  output spi_cs, output spi_sclk, output spi_mosi,
);

reg [15:0] waddr = 0;
wire loading = waddr < 16'h4000;
assign loaded = !loading;

wire rom_ready;
wire [15:0] rom_out;

reg [1:0] ram_ready = 2;

ROM rom (
  .clk(clk),
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
  .WREN(loading && rom_ready),
  .MASKWREN(4'b1111),
  .DATAIN(loading ? rom_out : 16'b0),
  .STANDBY(1'b0),
  .SLEEP(1'b0),
  .POWEROFF(1'b1),
  .DATAOUT(out),
);

always @(posedge clk) begin
  if (loading && rom_ready) begin
    if (ram_ready > 0) begin
      ram_ready <= ram_ready - 1;
    end else begin
      waddr <= waddr + 1;
    end
  end
end

endmodule
