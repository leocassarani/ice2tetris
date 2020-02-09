module ps2_receiver (
  input clk,
  inout ps2_clk, ps2_data,
  input tx,
  input [7:0] tx_data,
  output reg [7:0] out,
  output reg idle_out,
);

parameter [0:255] PARITY = {
  1'b1, 1'b0, 1'b0, 1'b1, 1'b0, 1'b1, 1'b1, 1'b0,
  1'b0, 1'b1, 1'b1, 1'b0, 1'b1, 1'b0, 1'b0, 1'b1,
  1'b0, 1'b1, 1'b1, 1'b0, 1'b1, 1'b0, 1'b0, 1'b1,
  1'b1, 1'b0, 1'b0, 1'b1, 1'b0, 1'b1, 1'b1, 1'b0,
  1'b0, 1'b1, 1'b1, 1'b0, 1'b1, 1'b0, 1'b0, 1'b1,
  1'b1, 1'b0, 1'b0, 1'b1, 1'b0, 1'b1, 1'b1, 1'b0,
  1'b1, 1'b0, 1'b0, 1'b1, 1'b0, 1'b1, 1'b1, 1'b0,
  1'b0, 1'b1, 1'b1, 1'b0, 1'b1, 1'b0, 1'b0, 1'b1,
  1'b0, 1'b1, 1'b1, 1'b0, 1'b1, 1'b0, 1'b0, 1'b1,
  1'b1, 1'b0, 1'b0, 1'b1, 1'b0, 1'b1, 1'b1, 1'b0,
  1'b1, 1'b0, 1'b0, 1'b1, 1'b0, 1'b1, 1'b1, 1'b0,
  1'b0, 1'b1, 1'b1, 1'b0, 1'b1, 1'b0, 1'b0, 1'b1,
  1'b1, 1'b0, 1'b0, 1'b1, 1'b0, 1'b1, 1'b1, 1'b0,
  1'b0, 1'b1, 1'b1, 1'b0, 1'b1, 1'b0, 1'b0, 1'b1,
  1'b0, 1'b1, 1'b1, 1'b0, 1'b1, 1'b0, 1'b0, 1'b1,
  1'b1, 1'b0, 1'b0, 1'b1, 1'b0, 1'b1, 1'b1, 1'b0,
  1'b0, 1'b1, 1'b1, 1'b0, 1'b1, 1'b0, 1'b0, 1'b1,
  1'b1, 1'b0, 1'b0, 1'b1, 1'b0, 1'b1, 1'b1, 1'b0,
  1'b1, 1'b0, 1'b0, 1'b1, 1'b0, 1'b1, 1'b1, 1'b0,
  1'b0, 1'b1, 1'b1, 1'b0, 1'b1, 1'b0, 1'b0, 1'b1,
  1'b1, 1'b0, 1'b0, 1'b1, 1'b0, 1'b1, 1'b1, 1'b0,
  1'b0, 1'b1, 1'b1, 1'b0, 1'b1, 1'b0, 1'b0, 1'b1,
  1'b0, 1'b1, 1'b1, 1'b0, 1'b1, 1'b0, 1'b0, 1'b1,
  1'b1, 1'b0, 1'b0, 1'b1, 1'b0, 1'b1, 1'b1, 1'b0,
  1'b1, 1'b0, 1'b0, 1'b1, 1'b0, 1'b1, 1'b1, 1'b0,
  1'b0, 1'b1, 1'b1, 1'b0, 1'b1, 1'b0, 1'b0, 1'b1,
  1'b0, 1'b1, 1'b1, 1'b0, 1'b1, 1'b0, 1'b0, 1'b1,
  1'b1, 1'b0, 1'b0, 1'b1, 1'b0, 1'b1, 1'b1, 1'b0,
  1'b0, 1'b1, 1'b1, 1'b0, 1'b1, 1'b0, 1'b0, 1'b1,
  1'b1, 1'b0, 1'b0, 1'b1, 1'b0, 1'b1, 1'b1, 1'b0,
  1'b1, 1'b0, 1'b0, 1'b1, 1'b0, 1'b1, 1'b1, 1'b0,
  1'b0, 1'b1, 1'b1, 1'b0, 1'b1, 1'b0, 1'b0, 1'b1
};

parameter [3:0] BITS_PER_FRAME = 4'd11; // 11

parameter [3:0] idle                       = 4'd0,
                rx_clk_high                = 4'd1,
                rx_clk_low                 = 4'd2,
                rx_down_edge               = 4'd3,
                tx_force_clk_low           = 4'd4,
                tx_data_down               = 4'd5,
                tx_wait_first_down_edge    = 4'd6,
                tx_clk_low                 = 4'd7,
                tx_wait_up_edge            = 4'd8,
                tx_clk_high                = 4'd9,
                tx_wait_up_edge_before_ack = 4'd10,
                tx_wait_ack                = 4'd11,
                tx_got_ack                 = 4'd12,
                tx_no_ack                  = 4'd13;

reg [3:0] state = idle;

reg [3:0] rx_count = 0, tx_count = 0;
reg [10:0] frame;

reg [7:0] ps2_clk_debounce = 8'b10101010;
wire ps2_clk_high = ps2_clk_debounce[7:3] == 5'b11111;
wire ps2_clk_low  = ps2_clk_debounce[7:3] == 5'b0000;

wire ps2_clk_rx, ps2_data_rx;

reg ps2_clk_output_enable = 0;
reg ps2_data_output_enable = 0;

reg ps2_clk_output, ps2_data_output;

wire ps2_clk_tx = ps2_clk_output_enable ? ps2_clk_output : 0;
wire ps2_data_tx = ps2_data_output_enable ? ps2_data_output : 0;

(* PULLUP_RESISTOR = "10K" *)
SB_IO #(
  .PIN_TYPE(6'b1010_00),
  .PULLUP(1),
) ps2_clk_io (
  .PACKAGE_PIN(ps2_clk),
  .INPUT_CLK(clk),
  .OUTPUT_CLK(clk),
  .OUTPUT_ENABLE(ps2_clk_output_enable),
  .D_IN_0(ps2_clk_rx),
  .D_OUT_0(ps2_clk_tx),
);

(* PULLUP_RESISTOR = "10K" *)
SB_IO #(
  .PIN_TYPE(6'b1010_00),
  .PULLUP(1),
) ps2_data_io (
  .PACKAGE_PIN(ps2_data),
  .INPUT_CLK(clk),
  .OUTPUT_CLK(clk),
  .OUTPUT_ENABLE(ps2_data_output_enable),
  .D_IN_0(ps2_data_rx),
  .D_OUT_0(ps2_data_tx),
);

always @(posedge clk) begin
  ps2_clk_debounce <= { ps2_clk_debounce[6:0], ps2_clk_rx };

  case (state)
    idle: begin
      idle_out <= 1;
      rx_count <= 0;
      tx_count <= 0;

      // If the device pulls the clock line low, start receiving.
      if (ps2_clk_low) begin
        idle_out <= 0;
        state <= rx_down_edge;
      end else if (tx) begin
        frame <= { 1'b0, PARITY[tx_data], 1'b1, tx_data }; // 0 = padding
        state <= tx_force_clk_low;
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
      frame <= { ps2_data_rx, frame[10:1] };
      rx_count <= rx_count + 1;
      state <= rx_clk_low;
    end

    tx_force_clk_low: begin
      ps2_clk_output <= 0;
      ps2_clk_output_enable <= 1;

      delay_100us_enable <= 1;

      if (delay_100us) begin
        state <= tx_data_down;
      end
    end

    tx_data_down: begin
      ps2_data_output <= 0;
      ps2_data_output_enable <= 1;

      delay_20us_enable <= 1;

      if (delay_20us) begin
        ps2_clk_output_enable <= 0;
        state <= tx_wait_first_down_edge;
      end
    end

    tx_wait_first_down_edge: begin
      // TODO: wait 63 clock cycles?!
      if (ps2_clk_low) begin
        state <= tx_clk_low;
      end
    end

    tx_clk_low: begin
      tx_count <= tx_count + 1;
      ps2_data_output <= frame[0];
      frame <= { 1'b0, frame[10:1] };
      state <= tx_wait_up_edge;
    end

    tx_wait_up_edge: begin
      // Subtract one because the start 0 bit is implicitly sent at the
      // beginning of the transmission process.
      if (tx_count == (BITS_PER_FRAME - 1)) begin
        state <= tx_wait_up_edge_before_ack;
      end else if (ps2_clk_high) begin
        state <= tx_clk_high;
      end
    end

    tx_clk_high: begin
      if (ps2_clk_low) begin
        state <= tx_clk_low;
      end
    end

    tx_wait_up_edge_before_ack: begin
      ps2_data_output_enable <= 0;

      if (ps2_clk_high) begin
        state <= tx_wait_ack;
      end
    end

    tx_wait_ack: begin
      if (ps2_clk_low) begin
        state <= ps2_data_rx ? tx_got_ack : tx_no_ack;
      end
    end

    tx_got_ack, tx_no_ack: begin
      if (ps2_clk_high) begin
        state <= idle;
      end
    end
  endcase
end

parameter [10:0] DELAY_100US = 11'd1200; // 100µs × 12MHz = 1200
parameter [7:0] DELAY_20US = 8'd240;     // 20µs × 12MHz = 240

reg delay_100us_enable, delay_20us_enable;

reg [10:0] delay_100us_count;
wire delay_100us = delay_100us_count == DELAY_100US;

reg [7:0] delay_20us_count;
wire delay_20us = delay_20us_count == DELAY_20US;

// TODO: extract into a parameterised module.
always @(posedge clk) begin
  if (delay_100us_enable) begin
    if (!delay_100us) begin
      delay_100us_count <= delay_100us_count + 1;
    end
  end else begin
    delay_100us_count <= 0;
  end

  if (delay_20us_enable) begin
    if (!delay_20us) begin
      delay_20us_count <= delay_20us_count + 1;
    end
  end else begin
    delay_20us_count <= 0;
  end
end

endmodule
