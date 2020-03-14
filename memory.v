`default_nettype none
`timescale 1ns / 1ps

module memory (
  input clk,
  input load,
  input [2:0] buttons,
  input [15:0] address,
  input [15:0] in,
  output [15:0] out
);

wire [15:0] ram_out, keyboard_out;
assign out = address[14] ? keyboard_out : ram_out;

ram ram (
  .clk(clk),
  .load(load),
  .address(address[13:0]),
  .in(in),
  .out(ram_out)
);

keyboard keyboard (
  .clk(clk),
  .buttons(buttons),
  .out(keyboard_out)
);

endmodule
