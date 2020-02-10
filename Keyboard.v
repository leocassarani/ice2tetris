module Keyboard (
  input clk,
  inout ps2_clk, ps2_data,
  input btn1,
  output idle_out,
  output [7:0] out,
);

reg [1:0] state = 0;

reg tx = 0;
reg [7:0] tx_data = 8'hF4; // Enable scanning

wire ps2_ready;
assign idle_out = ps2_ready;

wire [3:0] ps2_state;

wire [7:0] ps2_out;
assign out = ps2_out;

reg state;

always @(posedge clk) begin
  tx <= ps2_ready && ps2_out == 8'hAA;
end

ps2_receiver ps2 (
  .clk(clk),
  .ps2_clk(ps2_clk),
  .ps2_data(ps2_data),
  .tx(tx),
  .tx_data(tx_data),
  .ready(ps2_ready),
  .out(ps2_out),
  .out_state(ps2_state),
);

endmodule
