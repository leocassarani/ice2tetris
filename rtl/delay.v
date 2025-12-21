`default_nettype none

module delay #(
  parameter DURATION = 0,
  parameter CONTINUOUS = 0
) (
  input clk,
  input enable,
  output done
);

// Subtract one so we stop after DURATION clock cycles.
localparam MAX = DURATION - 1;

// Add 1 to ensure we maintain an upper bound if DURATION is a power of 2.
localparam BIT_LENGTH = $clog2(MAX) + 1;

reg [(BIT_LENGTH - 1):0] count = 0;
assign done = count == MAX;

always @(posedge clk) begin
  if (enable) begin
    if (done && CONTINUOUS) begin
      count <= 0;
    end else if (!done) begin
      count <= count + 1;
    end
  end else begin
    count <= 0;
  end
end

endmodule
