`default_nettype none

module Memory (
  input clk,
  input load,
  input [15:0] address,
  input [15:0] in,

  input vga_h_sync, vga_v_sync,
  input [3:0] vga_red, vga_green, vga_blue,
  input [2:0] kbd_buttons,

  output busy,
  output [15:0] out,
);

wire [15:0] ram_out, screen_out, kbd_out;

wire ram_select_0 = !address[14];
wire screen_select_0 = address[14] && !address[13];

reg ram_select_1, screen_select_1;

assign out = ram_select_1 ? (
  ram_out
) : (
  screen_select_1 ? screen_out : kbd_out
);

RAM ram (
  .clk(clk),
  .load(ram_select_0 && load),
  .address(address[13:0]),
  .in(in),
  .out(ram_out),
);

Screen screen (
  .clk(clk),
  .vram_load(screen_select_0 && load),
  .vram_addr(address[12:0]),
  .vram_din(in),
  .vram_busy(busy),
  .vram_dout(screen_out),
  .vga_h_sync(vga_h_sync),
  .vga_v_sync(vga_v_sync),
  .vga_red(vga_red),
  .vga_green(vga_green),
  .vga_blue(vga_blue),
);

Keyboard keyboard (
  .clk(clk),
  .buttons(kbd_buttons),
  .out(kbd_out),
);

always @(posedge clk) begin
  ram_select_1 <= ram_select_0;
  screen_select_1 <= screen_select_0;
end

endmodule
