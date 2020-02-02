module CPU (
  input clk, reset,
  input [15:0] instruction,
  output [15:0] pc,
);

reg [15:0] a_reg, d_reg;

always @(posedge clk) begin
  if (instruction[15]) begin
    if (instruction[5]) begin
      a_reg <= comp;
    end

    if (instruction[4]) begin
      d_reg <= comp;
    end
  end else begin
    a_reg <= instruction;
  end
end

wire [15:0] comp;
wire zero, negative;

wire jump = instruction[15] & (
  (instruction[2] & negative) |
  (instruction[1] & zero) |
  (instruction[0] & ~(negative | zero))
);

ALU alu (
  .x(d_reg),
  .y(a_reg), // TODO: A or M
  .zx(instruction[11]),
  .nx(instruction[10]),
  .zy(instruction[9]),
  .ny(instruction[8]),
  .f(instruction[7]),
  .no(instruction[6]),
  .out(comp),
  .zr(zero),
  .ng(negative),
);

ProgramCounter program_counter (
  .clk(clk),
  .reset(reset),
  .in(a_reg),
  .load(jump),
  .inc(1),
  .out(pc),
);

endmodule

module ProgramCounter (
  input clk, reset, inc, load,
  input [15:0] in,
  output reg [15:0] out,
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
