module Computer (
  input CLK,
  inout P1B1, P1B3,
  input BTN1,
  output P1A1, P1A2, P1A3, P1A4, P1A7, P1A8, P1A9, P1A10,
  output LEDR_N, LEDG_N,
);

wire [7:0] keyboard_out;

wire caps_lock;
assign LEDG_N = !caps_lock;

seven_seg_ctrl seven_segment (
  .clk(CLK),
  .din(keyboard_out),
  .dout({ P1A10, P1A9, P1A8, P1A7, P1A4, P1A3, P1A2, P1A1 }),
);

Keyboard keyboard (
  .clk(CLK),
  .ps2_clk(P1B3),
  .ps2_data(P1B1),
  .btn1(BTN1),
  .idle_out(LEDR_N),
  .caps_lock(caps_lock),
  .key_press(keyboard_out),
);

endmodule
