module Keyboard (
  input clk,
  input [2:0] buttons,
  output reg [15:0] out,
);

always @(posedge clk) begin
  if (buttons[2]) begin
    out <= 140; // esc
  end else if (buttons[1]) begin
    out <= 130; // left arrow
  end else if (buttons[0]) begin
    out <= 132; // right arrow
  end else begin
    out <= 0;   // no key pressed
  end
end

endmodule
