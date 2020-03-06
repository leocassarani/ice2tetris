module CPU (
  input clk, reset,
  input [15:0] instruction,
  input [15:0] memory_in,

  output memory_write,
  output [14:0] memory_address,
  output [15:0] memory_out,
  output [15:0] pc,
);

reg [15:0] a_reg;
reg [15:0] d_reg;

wire [15:0] alu_out;
wire zero, negative;

wire jump = instruction[15] && (
  (instruction[2] && negative) ||
  (instruction[1] && zero) ||
  (instruction[0] && !(negative || zero))
);

assign memory_write = instruction[15] && instruction[3];
assign memory_address = a_reg[14:0];
assign memory_out = alu_out;

always @(posedge clk) begin
  if (instruction[15]) begin
    if (instruction[5]) begin
      a_reg <= alu_out;
    end

    if (instruction[4]) begin
      d_reg <= alu_out;
    end
  end else begin
    a_reg <= instruction;
  end
end

ALU alu (
  .x(d_reg),
  .y(instruction[12] ? memory_in : a_reg),
  .zx(instruction[11]),
  .nx(instruction[10]),
  .zy(instruction[9]),
  .ny(instruction[8]),
  .f(instruction[7]),
  .no(instruction[6]),
  .out(alu_out),
  .zr(zero),
  .ng(negative),
);

ProgramCounter program_counter (
  .clk(clk),
  .reset(reset),
  .in(a_reg),
  .load(jump),
  .inc(1'b1),
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
