module ps2_receiver (
  input clk,
  input ps2_clk, ps2_data,
  output reg [7:0] out,
  output reg ready,
  output reg parity,
);

parameter [3:0] BITS_PER_FRAME = 4'd11; // 11

parameter [1:0] idle            = 2'd0,
                rx_clk_high     = 2'd1,
                rx_clk_low      = 2'd2,
                rx_down_edge    = 2'd3;

reg [1:0] state = idle;

reg [3:0] rx_count = 0;
reg [10:0] frame;

reg [7:0] ps2_clk_debounce = 8'b10101010;
wire ps2_clk_high = ps2_clk_debounce[7:3] == 5'b11111;
wire ps2_clk_low = ps2_clk_debounce[7:3] == 5'b0000;

always @(posedge clk) begin
  ps2_clk_debounce <= { ps2_clk_debounce[6:0], ps2_clk };

  case (state)
    idle: begin
      rx_count <= 0;

      // If the device pulls the clock line low, start receiving.
      if (ps2_clk_low) begin
        ready <= 0;
        state <= rx_down_edge;
      end
    end

    rx_clk_high: begin
      if (rx_count == BITS_PER_FRAME) begin
        // TODO: check parity and go back to idle if an error has occurred.
        out <= frame[8:1];
        ready <= 1;
        state <= idle;
      end else if (ps2_clk_low) begin
        state <= rx_down_edge;
      end
    end

    rx_clk_low: begin
      if (ps2_clk_high) begin
        state <= rx_clk_high;
      end
    end

    rx_down_edge: begin
      // Shift to the right so that by the end, the first bit becomes the LSB.
      frame <= { ps2_data, frame[10:1] };
      rx_count <= rx_count + 1'b1;
      state <= rx_clk_low;
    end
  endcase
end

endmodule
