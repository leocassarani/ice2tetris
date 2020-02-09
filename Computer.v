module Computer (
  input CLK,
  input P1B1, P1B3,
  output P1A1, P1A2, P1A3, P1A4, P1A7, P1A8, P1A9, P1A10,
  output LEDR_N,
);

wire [7:0] ps2_out;

seven_seg_ctrl seven_segment (
  .clk(CLK),
  .din(ps2_out),
  .dout({ P1A10, P1A9, P1A8, P1A7, P1A4, P1A3, P1A2, P1A1 }),
);

ps2_receiver ps2 (
  .clk(CLK),
  .ps2_clk(P1B3),
  .ps2_data(P1B1),
  .out(ps2_out),
  .ready(LEDR_N),
);

endmodule
