`default_nettype none
`timescale 1ns / 1ps

module memory (
  input clk,
  input load,
  input [15:0] address,
  input [15:0] in,

  output vga_h_sync, vga_v_sync,
  output [3:0] vga_red, vga_green, vga_blue,
  inout ps2_clk, ps2_data,

  output busy,
  output [15:0] out
);

wire [15:0] ram_out, screen_out, kbd_out;

wire ram_select_0 = !address[14];
wire screen_select_0 = address[14] && !address[13];

reg ram_select_1, screen_select_1;

// We need to use the delayed ram_select_1 and screen_select_1 signals in
// order to match the one-clock delay between requesting a memory read and
// receiving the results, otherwise we'd run the risk of propagating the
// output of a memory module that hasn't had enough time to process a read.
assign out = ram_select_1 ? (
  ram_out
) : (
  screen_select_1 ? screen_out : kbd_out
);

ram ram (
  .clk(clk),
  .load(ram_select_0 && load),
  .address(address[13:0]),
  .in(in),
  .out(ram_out)
);

screen screen (
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
  .vga_blue(vga_blue)
);

keyboard keyboard (
  .clk(clk),
  .ps2_clk(ps2_clk),
  .ps2_data(ps2_data),
  .out(kbd_out)
);

always @(posedge clk) begin
  ram_select_1 <= ram_select_0;
  screen_select_1 <= screen_select_0;
end

endmodule
