module Memory (
  input clk,
  input [15:0] in,
  input load,
  input [14:0] address,
  output [15:0] out,
);

RAM ram (
  .clk(clk),
  .in(in),
  .load(load & ~address[14]),
  .address(address[13:0]),
  .out(out),
);

endmodule

module RAM (
  input clk,
  input [15:0] in,
  input load,
  input [13:0] address,
  output [15:0] out,
);

SB_SPRAM256KA spram (
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
