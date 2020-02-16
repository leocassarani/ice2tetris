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
wire fetch = h_line >= 640 && h_line < 720;

wire [3:0] red = { P1A4, P1A3, P1A2, P1A1 };
wire [3:0] blue = { P1A10, P1A9, P1A8, P1A7 };
wire [3:0] green = { P1B4, P1B3, P1B2, P1B1 };

assign P1B7 = h_sync;
assign P1B8 = v_sync;

wire [15:0] vram_out;
wire vram_ready;

assign LEDR_N = !vram_ready;

// reg [1279:0] line;

// wire [10:0] index = 1279 - (8 * (h_line[9:2] + 1));

wire [3:0] index = 15 - (8 * h_line[2]);
wire [7:0] pixel = display ? vram_out[index:(index - 7)] : 8'b0;

//assign red = display ? channel(2'b11) : 4'b0;
//assign green = display ? channel(2'b10) : 4'b0;
//assign blue = display ? channel(2'b00) : 4'b0;

assign red = channel(pixel[5:4]);
assign green = channel(pixel[3:2]);
assign blue = channel(pixel[1:0]);

// reg [13:0] address = 0;

wire [13:0] address = display ? (80 * v_line[9:2]) + h_line[9:3] : 14'b0;

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
  .raddr(address),
  .out(vram_out),
  .loaded(vram_ready),

  .spi_cs(FLASH_SSB),
  .spi_sclk(FLASH_SCK),
  .spi_mosi(FLASH_IO0),
  .spi_miso(FLASH_IO1),
);

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

    //if (fetch) begin
      //if (v_line >= 480) begin
        //address <= h_line - 640;
      //end else begin
        //address <= (80 * (v_line[9:2] + 1)) + (h_line - 640);
      //end

      // line[1279 - (16 * (h_line - 640)):1279 - (16 * (h_line - 640) + 16)] <= vram_out;

      //if (h_line > 640) begin
        //line <= { line[1263:0], vram_out };
      //end
    //end
  end
end

function [4:0] channel(input [2:0] color);
  case (color)
    2'b00: channel = 4'b0000;
    2'b01: channel = 4'b0101;
    2'b10: channel = 4'b1010;
    2'b11: channel = 4'b1111;
  endcase
endfunction

endmodule
