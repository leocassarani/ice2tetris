module Computer (
  input CLK,
  output LEDR_N, LEDG_N,
  output P1A1, P1A2, P1A3, P1A4, P1A7, P1A8, P1A9, P1A10,
);

reg [23:0] clkdiv = 0;
reg clkdiv_pulse = 0;
reg flash = 0;

always @(posedge CLK) begin
  if (clkdiv == 12000000) begin
    clkdiv <= 0;
    clkdiv_pulse <= 1;
  end else begin
    clkdiv <= clkdiv + 1;
    clkdiv_pulse <= 0;
  end
end

reg [7:0] value = 0;

always @(posedge clkdiv_pulse) begin
  flash <= ~flash;
  value <= value + 1;
end

assign LEDR_N = flash;
assign LEDG_N = !flash;

Screen screen (
  .clk(CLK),
  .value(value),
  .seven_segment({ P1A10, P1A9, P1A8, P1A7, P1A4, P1A3, P1A2, P1A1 }),
);

endmodule
