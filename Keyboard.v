module Keyboard (
  input clk,
  input ps2_data,
  inout ps2_clk,
  output reg [15:0] out,
);

wire [7:0] keyboard_data;

always @(posedge clk) begin
  out <= {8'b0, keyboard_data};
end

ps2_receiver ps2_keyboard (
  .clk(clk),
  .ps2_clk(ps2_clk),
  .ps2_data(ps2_data),
  .out(keyboard_data),
);

endmodule

module ps2_receiver (
  input clk,
  inout ps2_clk,
  input ps2_data,
  output reg [7:0] out,
);

parameter [3:0] BITS_PER_FRAME = 4'd11;

parameter [2:0] idle            = 3'd0,
                rx_clk_high     = 3'd1,
                rx_clk_low      = 3'd2,
                rx_down_edge    = 3'd3,
                rx_data_ready   = 3'd4;

reg [2:0] state = idle;

reg [3:0] rx_count = 0;
reg [10:0] frame;

assign ps2_clk = 1'bZ;

always @(posedge clk) begin
  case (state)
    idle: begin
      rx_count <= 0;

      // If the device pulls the clock line low, start receiving.
      if (!ps2_clk) begin
        state <= rx_down_edge;
      end
    end

    rx_clk_high: begin
      if (rx_count == BITS_PER_FRAME) begin
        // TODO: check parity and go back to idle if an error had occurred.
        state <= rx_data_ready;
      end else if (!ps2_clk) begin
        state <= rx_down_edge;
      end
    end

    rx_clk_low: begin
      if (ps2_clk) begin
        state <= rx_clk_high;
      end
    end

    rx_down_edge: begin
      // Shift to the right so that by the end, the first bit becomes the LSB.
      frame <= { ps2_data, frame[10:1] };
      rx_count <= rx_count + 1;
      state <= rx_clk_low;
    end

    rx_data_ready: begin
      // TODO: do we need this state?
      out <= frame[8:1];
      state <= idle;
    end
  endcase
end

endmodule
