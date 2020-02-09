module ps2_receiver (
  input clk,
  inout ps2_clk, ps2_data,
  input tx,
  output reg [7:0] out,
  output reg idle_out,
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

reg [9:0] clkdiv;
reg clkpulse;

parameter [10:0] txmsg = 11'b0_1111_1111_11;
reg [3:0] txdata;

// 0xfe = 0 0111 1111 01

always @(posedge clk) begin
  if (clkdiv == 10'd1000) begin
    clkdiv <= 0;
    clkpulse <= 1;

    if (!tx) begin
      txdata <= 0;
    end else if (txdata == 10) begin
      txdata <= 0;
    end else begin
      txdata <= txdata + 1;
    end
  end else begin
    clkdiv <= clkdiv + 1;
    clkpulse <= 0;
  end
end

wire ps2_data_tx = txmsg[txdata];

wire ps2_clk_rw;
wire ps2_data_rw;

SB_IO #(
  .PIN_TYPE(6'b1010_00),
  .PULLUP(1),
) ps2_clk_io (
  .PACKAGE_PIN(ps2_clk),
  .INPUT_CLK(clk),
  .OUTPUT_CLK(clk),
  .OUTPUT_ENABLE(tx),
  .D_IN_0(ps2_clk_rw),
  .D_OUT_0(clkpulse),
);

SB_IO #(
  .PIN_TYPE(6'b1010_00),
  .PULLUP(1),
) ps2_data_io (
  .PACKAGE_PIN(ps2_data),
  .INPUT_CLK(clk),
  .OUTPUT_CLK(clk),
  .OUTPUT_ENABLE(tx),
  .D_IN_0(ps2_data_rw),
  .D_OUT_0(ps2_data_tx),
);

always @(posedge clk) begin
  ps2_clk_debounce <= { ps2_clk_debounce[6:0], ps2_clk_rw };

  case (state)
    idle: begin
      rx_count <= 0;
      idle_out <= 1;

      // If the device pulls the clock line low, start receiving.
      if (ps2_clk_low) begin
        idle_out <= 0;
        state <= rx_down_edge;
      end
    end

    rx_clk_high: begin
      if (rx_count == BITS_PER_FRAME) begin
        // TODO: check parity and go back to idle if an error has occurred.
        out <= frame[8:1];
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
      frame <= { ps2_data_rw, frame[10:1] };
      rx_count <= rx_count + 1'b1;
      state <= rx_clk_low;
    end
  endcase
end

endmodule
