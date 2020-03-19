`default_nettype none

module VRAM (
  input clk,

  input p_read,
  input [12:0] p_addr,

  input s_write,
  input [12:0] s_addr,
  input [15:0] s_din,

  output s_busy,
  output [15:0] p_dout,
  output [15:0] s_dout,
);

wire load = !p_read && s_write;
wire [15:0] in = p_read ? 16'b0 : s_din;
wire [13:0] address = { 1'b0, p_read ? p_addr : s_addr };
wire [15:0] out;

assign s_busy = p_read;
assign p_dout = p_read ? out : 16'b0;
assign s_dout = p_read ? 16'b0 : out;

SB_SPRAM256KA ram (
  .CLOCK(clk),
  .CHIPSELECT(1'b1),
  .ADDRESS(address),
  .WREN(load),
  .MASKWREN(4'b1111),
  .DATAIN(in),
  .STANDBY(1'b0),
  .SLEEP(1'b0),
  .POWEROFF(1'b1),
  .DATAOUT(out),
);

endmodule
