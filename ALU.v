module ALU (
  input [15:0] x,
  input [15:0] y,
  input zx, nx, zy, ny, f, no,
  output [15:0] out,
  output zr, ng,
);

wire [15:0] x_result;
wire [15:0] y_result;

Mux4 x_mux (
  .a(x),
  .b(~x),
  .c(0),
  .d(~0),
  .sel({zx, nx}),
  .out(x_result),
);

Mux4 y_mux (
  .a(y),
  .b(~y),
  .c(0),
  .d(~0),
  .sel({zy, ny}),
  .out(y_result),
);

wire [15:0] result = f ? x_result + y_result : x_result & y_result;
assign out = no ? ~result : result;

assign zr = ~|out[15:0]; // zr = NOR(out)
assign ng = out[15];

endmodule

module Mux4 (
  input [15:0] a,
  input [15:0] b,
  input [15:0] c,
  input [15:0] d,
  input [1:0] sel,
  output [15:0] out,
);

assign out = sel[1] ? (
  sel[0] ? d : c
) : (
  sel[0] ? b : a
);

endmodule
