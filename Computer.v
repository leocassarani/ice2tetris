module Computer (
  input CLK,
  input FLASH_IO1,
  input BTN1,
  output LEDR_N,
  output P1A1, P1A2, P1A3, P1A4, P1A7, P1A8, P1A9, P1A10,
  output P1B1, P1B2, P1B3, P1B4, P1B7, P1B8,
  output FLASH_SCK, FLASH_SSB, FLASH_IO0,
);

wire clk_out;

reg [9:0] h_line, v_line;

wire display = h_line < 640 && v_line < 480;
wire h_sync = h_line < 656 || h_line >= 752;
wire v_sync = v_line < 490 || v_line >= 492;

wire [3:0] red = { P1A4, P1A3, P1A2, P1A1 };
wire [3:0] blue = { P1A10, P1A9, P1A8, P1A7 };
wire [3:0] green = { P1B4, P1B3, P1B2, P1B1 };

assign P1B7 = h_sync;
assign P1B8 = v_sync;

wire [15:0] vram_out;
wire vram_ready;

assign LEDR_N = !vram_ready;

wire [7:0] pixel = h_line[2] ? scanline_rdata[15:8] : scanline_rdata[7:0];

assign red = channel(pixel[5:4]);
assign green = channel(pixel[3:2]);
assign blue = channel(pixel[1:0]);

reg [13:0] vram_addr = 0;
reg [10:0] scanline_raddr = 0;
reg [10:0] scanline_waddr = 0;
reg [15:0] scanline_wdata;
reg [15:0] scanline_rdata;

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
  .raddr(vram_addr),
  .out(vram_out),
  .loaded(vram_ready),

  .spi_cs(FLASH_SSB),
  .spi_sclk(FLASH_SCK),
  .spi_mosi(FLASH_IO0),
  .spi_miso(FLASH_IO1),
);

SB_RAM40_4K #(
  .WRITE_MODE(0),
  .READ_MODE(0),
) scanline_ram (
  .RCLK(clk_out),
  .RCLKE(1'b1),
  .RE(display),
  .RADDR(scanline_raddr),
  .RDATA(scanline_rdata),
  .WCLK(clk_out),
  .WCLKE(1'b1),
  .WE(!display),
  .WADDR(scanline_waddr),
  .WDATA(scanline_wdata),
);

wire [7:0] vram_idx = h_line < 640 ? 0 : h_line - 640;
wire [7:0] scanline_idx = vram_idx ? vram_idx - 2 : 0;
wire [13:0] vram_page = v_line < 480 ? 2 + (80 * v_line[9:3]) : 0;

wire [9:0] next_hline = h_line + 2;

always @(posedge clk_out) begin
  if (vram_ready) begin
    vram_addr <= vram_page + vram_idx;
    scanline_waddr <= scanline_idx;
    scanline_wdata <= vram_out;
  end

  scanline_raddr <= next_hline[9:3];
end

always @(posedge clk_out) begin
  if (vram_ready) begin
    if (h_line == 799) begin
      h_line <= 0;

      if (v_line == 524) begin
        v_line <= 0;
      end else begin
        v_line <= v_line + 1;
      end
    end else begin
      h_line <= h_line + 1;
    end
  end
end

function [4:0] channel(input [2:0] color);
  channel = { color[1], color[0], color[1], color[0] };
endfunction

endmodule
