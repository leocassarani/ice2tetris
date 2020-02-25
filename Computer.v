`default_nettype none

module Computer (
  input CLK,
  input FLASH_IO1,
  input BTN1, BTN2, BTN3,
  output LEDR_N,
  output P1A1, P1A2, P1A3, P1A4, P1A7, P1A8, P1A9, P1A10,
  output P1B1, P1B2, P1B3, P1B4, P1B7, P1B8, P1B9, P1B10,
  output FLASH_SCK, FLASH_SSB, FLASH_IO0,
);

wire pll_out, pll_locked;
wire reset = !pll_locked;

//wire vram_ready;
//assign LEDR_N = !vram_ready;

wire [13:0] vram_raddr;
wire [15:0] vram_rdata;

reg [13:0] vram_waddr;
reg [15:0] vram_wdata;

reg vram_wren;
wire vram_rden, vram_wrack;

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
  .PLLOUTCORE(pll_out),
);

//VRAM vram (
  //.clk(pll_out),
  //.reset(reset),
  //.raddr(vram_raddr),
  //.rden(vram_rden),
  //.out(vram_rdata),
  //.loaded(vram_ready),

  //.spi_cs(FLASH_SSB),
  //.spi_sclk(FLASH_SCK),
  //.spi_mosi(FLASH_IO0),
  //.spi_miso(FLASH_IO1),
//);

shared_vram svram (
  .clk(pll_out),

  .rden(vram_rden),
  .raddr(vram_raddr),
  .rdata(vram_rdata),

  .wren(vram_wren),
  .waddr(vram_waddr),
  .wdata(vram_wdata),

  .wrack(vram_wrack),
);

VGA vga (
  .clk(pll_out),
  .clken(1),

  .vram_rdata(vram_rdata),
  .vram_raddr(vram_raddr),
  .vram_rden(vram_rden),

  .h_sync(P1B7),
  .v_sync(P1B8),

  .red({ P1A4, P1A3, P1A2, P1A1 }),
  .blue({ P1A10, P1A9, P1A8, P1A7 }),
  .green({ P1B4, P1B3, P1B2, P1B1 }),
);

reg written = 0;

always @(posedge pll_out) begin
  if (!written) begin
    if (vram_wrack) begin
      vram_wren <= 0;
      written <= 1;
    end else begin
      vram_wren <= BTN1;
      vram_wdata <= BTN3 ? 16'hffff : 16'b0;
    end
  end else if (!BTN1) begin
    written <= 0;
  end
end

always @(posedge BTN2) begin
  vram_waddr <= vram_waddr == (14'h2000 - 1) ? 0 : vram_waddr + 1;
end

endmodule
