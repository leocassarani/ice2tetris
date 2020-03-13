`default_nettype none

module memory (
  input clk,
  input load,
  input [15:0] address,
  input [15:0] in,
  output [15:0] out,
);

SB_SPRAM256KA ram (
  .CLOCK(clk),
  .CHIPSELECT(1'b1),
  .ADDRESS(address[13:0]),
  .WREN(load),
  .MASKWREN(4'b1111),
  .DATAIN(in),
  .STANDBY(1'b0),
  .SLEEP(1'b0),
  .POWEROFF(1'b1),
  .DATAOUT(out),
);

endmodule
