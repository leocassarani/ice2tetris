`default_nettype none

module VGA (
  input clk,
  input clken,

  input [15:0] vram_rdata,
  output [12:0] vram_raddr,
  output reg vram_rden,

  output h_sync, v_sync,
  output [3:0] red, green, blue,
);

localparam [6:0] H_BLANK = 64;
localparam [6:0] V_BLANK = 112;

localparam [9:0] H_MIN = 160 + H_BLANK;

reg [9:0] h_count = 0, v_count = 0;

wire h_sync_pulse = h_count >= 16 && h_count < 112;
wire h_display = h_count >= H_MIN && h_count < (H_MIN + 512);
wire h_end = h_count == 799;

wire v_sync_pulse = v_count >= 490 && v_count < 492;
wire v_display = v_count >= V_BLANK && v_count < (V_BLANK + 256);
wire v_end = v_count == 524;

wire [9:0] x = h_display ? h_count - H_MIN : 0;   // range: 0-511
wire [9:0] y = v_display ? v_count - V_BLANK : 0; // range: 0-255

reg [15:0] pixel_word;
reg pixel;

// In 640x480 @ 60Hz, both H- and V- sync signals have negative polarity.
assign h_sync = !h_sync_pulse;
assign v_sync = !v_sync_pulse;

wire display = h_display && v_display;

assign red   = { 4{ pixel } };
assign green = { 4{ pixel } };
assign blue  = { 4{ pixel } };

reg [6:0] vram_offset = 0;
wire [12:0] vram_line = 32 * y;
assign vram_raddr = vram_line + vram_offset;

always @(posedge clk) begin
  if (display) begin
    // Negate the pixel value so that 1 = black, 0 = white.
    pixel <= ~pixel_word[x[3:0]];

    case (x[3:0])
      4'b0000: begin
        pixel_word <= vram_rdata;
        pixel <= ~vram_rdata[0];
        vram_rden <= 0;
      end

      4'b1100: begin
        vram_offset <= vram_offset + 1;
        vram_rden <= 1;
      end
    endcase
  end else begin
    pixel <= 0;
    vram_offset <= 0;

    if (v_display && h_count >= H_MIN - 4 && h_count < H_MIN) begin
      vram_rden <= 1;
    end else begin
      vram_rden <= 0;
    end
  end
end

always @(posedge clk) begin
  //if (reset) begin // TODO
    //h_count <= 0;
    //v_count <= 0;
  //end
  //if (clken) begin
    if (h_end && v_end) begin
      h_count <= 0;
      v_count <= 0;
    end else if (h_end) begin
      h_count <= 0;
      v_count <= v_count + 1;
    end else begin
      h_count <= h_count + 1;
    end
  //end
end

endmodule
