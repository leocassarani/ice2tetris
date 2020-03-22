`default_nettype none

module CPU (
  input clk, reset,
  input [15:0] instruction,
  input mem_busy,
  input [15:0] mem_rdata,
  output mem_write,
  output [15:0] mem_address,
  output [15:0] mem_wdata,
  output reg [15:0] prog_counter,
);

reg [15:0] a_reg;
reg [15:0] d_reg;

assign mem_address = a_reg;
assign mem_write = state == write_back && d3;
assign mem_wdata = alu_out;

wire i = instruction[15];
wire a = instruction[12];

reg c1, c2, c3, c4, c5, c6;
reg d1, d2, d3;
reg j1, j2, j3;

reg [15:0] alu_x, alu_y;
wire [15:0] alu_out;
wire alu_zero, alu_neg;
wire alu_pos = !(alu_neg || alu_zero);

wire jump = (j1 && alu_neg) || (j2 && alu_zero) || (j3 && alu_pos);

localparam [2:0] inst_fetch  = 3'd0,
                 inst_decode = 3'd1,
                 mem_wait    = 3'd2,
                 mem_read    = 3'd3,
                 write_back  = 3'd4;

reg [2:0] state = inst_fetch;

ALU alu (
  .x(alu_x),
  .y(alu_y),
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
        if (i) begin // C-instruction
          { c1, c2, c3, c4, c5, c6 } <= instruction[11:6];
          { d1, d2, d3 } <= instruction[5:3];
          { j1, j2, j3 } <= instruction[2:0];

          alu_x <= d_reg;

          if (!a) begin
            alu_y <= a_reg;
            state <= write_back;
          end else if (!mem_busy) begin
            state <= mem_wait;
          end
        end else begin // A-instruction
          a_reg <= instruction;
          prog_counter <= prog_counter + 1;
          state <= inst_fetch;
        end
      end

      mem_wait: begin
        state <= mem_read;
      end

      mem_read: begin
        alu_y <= mem_rdata;
        state <= write_back;
      end

      write_back: begin
        if (!mem_busy) begin
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
      end
    endcase
  end
end

endmodule
