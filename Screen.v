`default_nettype none
`timescale 1ns / 1ps

module Screen (
  input clk,

  input vram_load,
  input [12:0] vram_addr,
  input [15:0] vram_din,

  output vram_busy,
  output [15:0] vram_dout,

  output vga_h_sync, vga_v_sync,
  output [3:0] vga_red, vga_green, vga_blue
);

wire vram_p_read;
wire [12:0] vram_p_addr;
wire [15:0] vram_p_dout;

VGA vga (
  .clk(clk),
  .vram_rdata(vram_p_dout),
  .vram_raddr(vram_p_addr),
  .vram_rden(vram_p_read),
  .h_sync(vga_h_sync),
  .v_sync(vga_v_sync),
  .red(vga_red),
  .green(vga_green),
  .blue(vga_blue)
);

VRAM vram (
  .clk(clk),
  .p_addr(vram_p_addr),
  .p_read(vram_p_read),
  .p_dout(vram_p_dout),
  .s_addr(vram_addr),
  .s_write(vram_load),
  .s_din(vram_din),
  .s_dout(vram_dout),
  .s_busy(vram_busy)
);

endmodule
