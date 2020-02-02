module Computer (
  input CLK,
  output LEDR_N, LEDG_N,
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

always @(posedge clkdiv_pulse) begin
  flash <= ~flash;
end

assign LEDR_N = flash;
assign LEDG_N = !flash;

endmodule
