module RAM (
  input clk,
  input [15:0] in,
  input load,
  input [13:0] address,
  output [15:0] out,
);

SB_SPRAM256KA spram (
  .CLOCK(clk),
  .CHIPSELECT(1),
  .ADDRESS(address),
  .WREN(load),
  .MASKWREN(4'b1111),
  .DATAIN(in),
  .STANDBY(0),
  .SLEEP(0),
  .POWEROFF(1),
  .DATAOUT(out),
);

endmodule
