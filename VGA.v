`default_nettype none

module VGA (
  input clk,
  input clken,

  input [15:0] vram_rdata,
  output reg [13:0] vram_raddr,

  output h_sync, v_sync,
  output [3:0] red, green, blue,
);

reg [9:0] h_count = 0, v_count = 0;

wire h_sync_pulse = h_count >= 656 && h_count < 752;
wire h_display = h_count < 640;
wire h_end = h_count == 799;

wire v_sync_pulse = v_count >= 490 && v_count < 492;
wire v_display = v_count < 480;
wire v_end = v_count == 524;

wire [9:0] x = h_display ? h_count : 0; // range: 0-639
wire [9:0] y = v_display ? v_count : 0; // range: 0-479

reg [15:0] pixel_word = 0;
wire [7:0] pixel = x[2] ? pixel_word[7:0] : pixel_word[15:8];

// In 640x480 @ 60Hz, both H- and V- sync signals have negative polarity.
assign h_sync = !h_sync_pulse;
assign v_sync = !v_sync_pulse;

wire display = h_display && v_display;

assign red = display ? { pixel[5:4], pixel[5:4] } : 0;
assign green = display ? { pixel[3:2], pixel[3:2] } : 0;
assign blue = display ? { pixel[1:0], pixel[1:0] } : 0;

// assign vram_raddr = display ? 1 + (80 * y[9:3] + x[9:3]) : 0;
reg [6:0] vram_offset = 0;
wire [13:0] vram_line = 10 * { y[9:3], 3'b000 };
assign vram_raddr = vram_line + vram_offset;

always @(posedge clk) begin
  // We want a new "pixel word" (2 pixels) every 8 clock cycles.
  if (x[2:0] == 3'b000) begin
    pixel_word <= vram_rdata;
  end else if (x[2:0] == 3'b100) begin
    vram_offset <= vram_offset + 1;
  end

  if (h_end) begin
    vram_offset <= &y[2:0] ? 80 : 0;
  end
end

always @(posedge clk) begin
  if (clken) begin
    if (h_end && v_end) begin
      h_count <= 0;
      v_count <= 0;
    end else if (h_end) begin
      h_count <= 0;
      v_count <= v_count + 1;
    end else begin
      h_count <= h_count + 1;
    end
  end
end

endmodule
