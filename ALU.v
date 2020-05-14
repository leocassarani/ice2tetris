`default_nettype none
`timescale 1ns / 1ps

module ALU (
  input [15:0] x,
  input [15:0] y,
  input zx, nx, zy, ny, f, no,
  output [15:0] out,
  output zero, neg
);

wire [15:0] x_result, y_result, result;

assign x_result = zx ? (nx ? ~16'b0 : 16'b0) : (nx ? ~x : x);
assign y_result = zy ? (ny ? ~16'b0 : 16'b0) : (ny ? ~y : y);

assign result = f ? x_result + y_result : x_result & y_result;
assign out = no ? ~result : result;

assign zero = ~|out; // zero = NOR(out)
assign neg = out[15];

endmodule
