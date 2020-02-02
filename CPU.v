module CPU (
  input clk, reset,
  output [14:0] pc,
);

ProgramCounter program_counter (
  .clk(clk),
  .reset(reset),
  .inc(1),
  .out(pc),
);

endmodule

module ProgramCounter (
  input clk, inc, reset,
  output reg [14:0] out,
);

always @(posedge clk) begin
  if (inc) begin
    out <= out + 1;
  end

  if (reset) begin
    out <= 0;
  end
end

endmodule
