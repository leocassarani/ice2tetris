module Memory (
  input clk,
  input [15:0] in,
  input load,
  input [14:0] address,
  inout ps2_clk, ps2_data,
  output [7:0] seven_segment,
  output [15:0] out,
);

wire [15:0] ram_out;
wire [7:0] keyboard_out;

assign out = address[14] ? keyboard_out : ram_out;

RAM ram (
  .clk(clk),
  .in(in),
  .load(load && !address[14]),
  .address(address[13:0]),
  .out(ram_out),
);

Screen screen (
  .clk(clk),
  .in(in),
  .load(load && address[14]),
  .address(address[13:0]),
  .seven_segment(seven_segment),
);

Keyboard keyboard (
  .clk(clk),
  .ps2_clk(ps2_clk),
  .ps2_data(ps2_data),
  .out(keyboard_out),
);

endmodule
