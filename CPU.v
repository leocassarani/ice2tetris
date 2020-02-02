module CPU (
  input clk, reset,
  input [15:0] instruction,
  output [14:0] pc,
);

reg [14:0] a_reg = 0;

always @(posedge clk) begin
  if (!instruction[15]) begin
    a_reg <= instruction[14:0];
  end
end

ProgramCounter program_counter (
  .clk(clk),
  .reset(reset),
  .in(a_reg),
  .load(instruction[15] && &instruction[2:0]),
  .inc(1),
  .out(pc),
);

endmodule

module ProgramCounter (
  input clk, reset, inc, load,
  input [14:0] in,
  output reg [14:0] out,
);

always @(posedge clk) begin
  if (reset) begin
    out <= 0;
  end else if (load) begin
    out <= in;
  end else if (inc) begin
    out <= out + 1;
  end
end

endmodule
