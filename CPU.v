`default_nettype none

module CPU (
  input clk, reset,
  input [15:0] instruction,
  output reg [15:0] prog_counter,
  output reg [15:0] a_reg,
  output reg [15:0] d_reg,
);

wire a;
wire c1, c2, c3, c4, c5, c6;
wire d1, d2, d3;

assign { a, c1, c2, c3, c4, c5, c6, d1, d2, d3 } = instruction[12:3];

wire [15:0] alu_out;
wire alu_zero, alu_neg;

ALU alu (
  .x(d_reg),
  .y(a_reg),
  .zx(c1),
  .nx(c2),
  .zy(c3),
  .ny(c4),
  .f(c5),
  .no(c6),
  .out(alu_out),
  .zero(alu_zero),
  .neg(alu_neg),
);

always @(posedge clk) begin
  if (instruction[15]) begin // C-instruction
    if (d1) begin            // Write to A register?
      a_reg <= alu_out;
    end

    if (d2) begin            // Write to D register?
      d_reg <= alu_out;
    end
  end else begin
    a_reg <= instruction;    // A-instruction
  end

  if (reset) begin
    prog_counter <= 0;
  end else begin
    prog_counter <= prog_counter + 1;
  end
end

endmodule
