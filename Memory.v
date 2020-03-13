`default_nettype none

module Memory (
  input clk,
  input [15:0] address,
  output [15:0] out,
);

SB_SPRAM256KA ram (
  .CLOCK(clk),
  .CHIPSELECT(1'b1),
  .ADDRESS(address[13:0]),
  .WREN(1'b0),
  .MASKWREN(4'b1111),
  .DATAIN(16'b0),
  .STANDBY(1'b0),
  .SLEEP(1'b0),
  .POWEROFF(1'b1),
  .DATAOUT(out),
);

endmodule
