`default_nettype none

module CPU (
  input clk, reset,
  input [15:0] instruction,
  output reg [15:0] prog_counter,
  output reg [15:0] a_reg,
  output reg [15:0] d_reg,
);

reg a;
reg c1, c2, c3, c4, c5, c6;
reg d1, d2, d3;
reg j1, j2, j3;

wire [15:0] alu_out;
wire alu_zero, alu_neg;
wire alu_pos = !(alu_neg || alu_zero);

wire jump = (j1 && alu_neg) || (j2 && alu_zero) || (j3 && alu_pos);

localparam [1:0] inst_fetch  = 2'd0,
                 inst_decode = 2'd1,
                 write_back  = 2'd2;

reg [1:0] state = inst_fetch;

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
  if (reset) begin
    prog_counter <= 0;
    a_reg <= 0;
    d_reg <= 0;
    state <= inst_fetch;
  end else begin
    case (state)
      inst_fetch: begin
        state <= inst_decode;
      end

      inst_decode: begin
        if (instruction[15]) begin
          // C-instruction
          { a, c1, c2, c3, c4, c5, c6, d1, d2, d3, j1, j2, j3 } <= instruction[12:0];
          state <= write_back;
        end else begin
          // A-instruction
          a_reg <= instruction;
          prog_counter <= prog_counter + 1;
          state <= inst_fetch;
        end
      end

      write_back: begin
        if (d1) begin // Write to A register?
          a_reg <= alu_out;
        end

        if (d2) begin // Write to D register?
          d_reg <= alu_out;
        end

        if (jump) begin
          prog_counter <= a_reg;
        end else begin
          prog_counter <= prog_counter + 1;
        end

        state <= inst_fetch;
      end
    endcase
  end
end

endmodule
