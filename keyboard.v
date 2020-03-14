`default_nettype none
`timescale 1ns / 1ps

module keyboard (
  input clk,
  input [2:0] buttons,
  output reg [15:0] out
);

always @(posedge clk) begin
  if (buttons[2]) begin
    out <= 130; // Left arrow
  end else if (buttons[1]) begin
    out <= 140; // Escape
  end else if (buttons[0]) begin
    out <= 132; // Right arrow
  end else begin
    out <= 0;   // No key pressed
  end
end

endmodule
