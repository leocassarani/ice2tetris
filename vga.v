`default_nettype none

module vga (
  input clk,

  input [15:0] vram_rdata,
  output [12:0] vram_raddr,
  output vram_rden,

  output h_sync, v_sync,
  output [3:0] red, green, blue,
);

localparam [9:0] WIDTH = 512;
localparam [8:0] HEIGHT = 256;

localparam [6:0] H_BLANK = 64;
localparam [6:0] V_BLANK = 112;

localparam [7:0] H_MIN = 160 + H_BLANK;
localparam [9:0] H_MAX = H_MIN + WIDTH;

localparam [6:0] V_MIN = V_BLANK;
localparam [8:0] V_MAX = V_MIN + HEIGHT;

reg [9:0] h_count = 0, v_count = 0;

wire h_sync_pulse = h_count >= 16 && h_count < 112;
wire h_display = h_count >= H_MIN && h_count < H_MAX;
wire h_end = h_count == 799;

wire v_sync_pulse = v_count >= 490 && v_count < 492;
wire v_display = v_count >= V_MIN && v_count < V_MAX;
wire v_end = v_count == 524;

wire [8:0] x = h_display ? h_count - H_MIN : 0; // range: 0-511
wire [7:0] y = v_display ? v_count - V_MIN : 0; // range: 0-255

// In 640x480 @ 60Hz, both H- and V-sync signals have negative polarity.
assign h_sync = ~h_sync_pulse;
assign v_sync = ~v_sync_pulse;

wire display = h_display && v_display;

// If we're in the rendering phase, then we want vram_offset to point to the
// offset of the _next_ 16-bit word of pixels that needs to be read from VRAM,
// so we add 1 to the result of dividing x by 16. If we're not rendering, then
// we set vram_offset to 0 in preparation for the first pixel of the new line.
wire [4:0] vram_offset = display ? x[8:4] + 1 : 0; // x[8:4] == x >> 4 == x / 16

// vram_addr is simply line offset (32 * y) + pixel word offset (x / 16).
assign vram_raddr = { y, vram_offset }; // { y, offset } == (y << 5) + offset == (y * 32) + offset

// Reading from VRAM takes 3 cycles, so during the active rendering phase, we
// want to request a read whenever there are 3 pixels left in the current
// 16-bit word, i.e. when the x value modulo 16 = 13. In addition, while we're
// in the horizontal back porch, we need to ask for the first pixel word
// 3 cycles ahead of hitting the visible area (as long as v_display is high).
assign vram_rden = (display && x[3:0] == 13 && x != WIDTH - 3) || (v_display && h_count == H_MIN - 3);

// Negate the pixel value so that 1 = black, 0 = white.
wire pixel = display ? ~vram_rdata[x[3:0]] : 0; // x[3:0] == x mod 16

// This is a black-and-white display, so we need to repeat the black or white
// pixel across the four bits of all three colours.
assign red   = { 4{ pixel } };
assign green = { 4{ pixel } };
assign blue  = { 4{ pixel } };

always @(posedge clk) begin
  if (h_end) begin
    h_count <= 0;
    v_count <= v_end ? 0 : v_count + 1;
  end else begin
    h_count <= h_count + 1;
  end
end

endmodule
