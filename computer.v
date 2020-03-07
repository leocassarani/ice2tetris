`default_nettype none
`timescale 1ns / 1ps

module computer (
  input CLK,
  output LEDR_N, LEDG_N
);

wire pll_out, pll_locked;

reg [24:0] clkdiv = 0;
reg clkdiv_pulse = 0;
reg flash = 0;

assign LEDR_N = flash;
assign LEDG_N = !flash;

SB_PLL40_PAD #(
  .FEEDBACK_PATH("SIMPLE"),
  .DIVR(4'b0000),        // DIVR = 0
  .DIVF(7'b1000010),     // DIVF = 66
  .DIVQ(3'b101),         // DIVQ = 5
  .FILTER_RANGE(3'b001) // FILTER_RANGE = 1
) pll_clock (
  .RESETB(1'b1),
  .BYPASS(1'b0),
  .LOCK(pll_locked),
  .PACKAGEPIN(CLK),
  .PLLOUTGLOBAL(pll_out)
);

always @(posedge pll_out) begin
  if (pll_locked) begin
    if (clkdiv == 25125000) begin
      clkdiv <= 0;
      clkdiv_pulse <= 1;
    end else begin
      clkdiv <= clkdiv + 1;
      clkdiv_pulse <= 0;
    end
  end
end

always @(posedge clkdiv_pulse) begin
  flash <= !flash;
end

endmodule
