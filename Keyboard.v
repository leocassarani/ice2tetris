module Keyboard (
  input clk,
  inout ps2_clk, ps2_data,
  input btn1,
  output idle_out,
  output reg [7:0] out,
);

reg [1:0] state = 0;

reg tx = 0;
reg [7:0] tx_data;

wire ps2_ready;
assign idle_out = ps2_ready;

wire [3:0] ps2_state;
wire [7:0] ps2_out;

localparam [1:0] idle = 2'd0,
                 wait_for_ack = 2'd1;

reg state;

always @(posedge clk) begin
  case (state)
    idle: begin
      tx <= 0;

      case (ps2_out)
        8'h16: out <= 8'h01;
        8'h1C: out <= 8'h0A;
        8'h1E: out <= 8'h02;
        8'h21: out <= 8'h0C;
        8'h23: out <= 8'h0D;
        8'h24: out <= 8'h0E;
        8'h25: out <= 8'h04;
        8'h26: out <= 8'h03;
        8'h2B: out <= 8'h0F;
        8'h2E: out <= 8'h05;
        8'h32: out <= 8'h0B;
        8'h36: out <= 8'h06;
        8'h3D: out <= 8'h07;
        8'h3E: out <= 8'h08;
        8'h44: out <= 8'h00;
        8'h45: out <= 8'h00;
        8'h46: out <= 8'h09;

        8'hAA: begin
          tx_data <= 8'hF4; // Enable scanning
          tx <= 1;
          state <= wait_for_ack;
        end

        8'hFA: begin
          // Do nothing
        end

        default: out <= ps2_out;
      endcase
    end

    wait_for_ack: begin
      tx <= 0;

      if (ps2_ready && ps2_out == 8'hFA) begin
        state <= idle;
      end
    end
  endcase
end

ps2_receiver ps2 (
  .clk(clk),
  .ps2_clk(ps2_clk),
  .ps2_data(ps2_data),
  .tx(tx),
  .tx_data(tx_data),
  .ready(ps2_ready),
  .out(ps2_out),
  .out_state(ps2_state),
);

endmodule
