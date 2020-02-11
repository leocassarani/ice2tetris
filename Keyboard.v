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
reg [7:0] param, key_release;

wire ps2_ready;
assign idle_out = ps2_ready;

wire [3:0] ps2_state;
wire [7:0] ps2_out;

localparam [2:0] idle = 3'd0,
                 key_down = 3'd1,
                 wait_for_ack = 3'd2,
                 wait_for_key_up_scan_code = 3'd3,
                 send_multi_byte_command = 3'd4;

reg state = idle;

always @(posedge clk) begin
  case (state)
    idle: begin
      tx <= 0;

      case (ps2_out)
        8'h58: begin
          if (ps2_ready) begin
            tx_data <= 8'hED;
            param <= 8'b100;
            tx <= 1;
            state <= send_multi_byte_command;
          end
        end

        8'hAA: begin
          if (ps2_ready) begin
            tx_data <= 8'hF4; // Enable scanning
            tx <= 1;
            state <= wait_for_ack;
          end
        end

        8'hFA: begin
           //Do nothing
        end

        8'hF0: begin
          state <= wait_for_key_up_scan_code;
        end

        default: begin
          if (key_release != ps2_out) begin
            state <= key_down;
          end
        end
      endcase
    end

    key_down: begin
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
        default: out <= ps2_out;
      endcase

      state <= idle;
    end

    wait_for_ack: begin
      tx <= 0;

      if (ps2_ready && ps2_out == 8'hFA) begin
        state <= idle;
      end
    end

    wait_for_key_up_scan_code: begin
      if (ps2_ready && ps2_out != 8'hF0) begin
        key_release <= ps2_out;
        out <= 0;
        state <= idle;
      end
    end

    send_multi_byte_command: begin
      tx <= 0;

      if (ps2_ready && ps2_out == 8'hFA) begin
        tx_data <= param;
        tx <= 1;
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
