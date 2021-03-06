`default_nettype none
`timescale 1ns / 1ps

module clock (
  input refclk,
  output locked,
  output out
);

`ifdef SYNTHESIS

SB_PLL40_PAD #(
  .FEEDBACK_PATH("SIMPLE"),
  .DIVR(4'b0000),        // DIVR = 0
  .DIVF(7'b1000010),     // DIVF = 66
  .DIVQ(3'b101),         // DIVQ = 5
  .FILTER_RANGE(3'b001)  // FILTER_RANGE = 1
) pll_clock (
  .RESETB(1'b1),
  .BYPASS(1'b0),
  .LOCK(locked),
  .PACKAGEPIN(refclk),
  .PLLOUTGLOBAL(out)
);

`else

assign locked = 1'b1;
assign out = refclk;

`endif

endmodule
