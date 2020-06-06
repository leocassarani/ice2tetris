`default_nettype none
`timescale 1ns / 1ps

module keyboard (
  input clk,
`ifdef VERILATOR
  input [7:0] key,
`endif
  inout ps2_clk, ps2_data,
  output [15:0] out
);

`ifdef VERILATOR

assign out = { 8'b0, key };

`else

localparam [7:0] LEFT_SHIFT   = 8'h12,
                 CAPS_LOCK    = 8'h58,
                 RIGHT_SHIFT  = 8'h59,
                 SELF_TEST    = 8'hAA,
                 EXTENDED     = 8'hE0,
                 CMD_SET_LEDS = 8'hED,
                 KEY_UP       = 8'hF0,
                 CMD_ENABLE   = 8'hF4,
                 ACK          = 8'hFA;

reg ps2_write;
reg [7:0] tx_data;
reg [7:0] cmd_params;

wire ps2_busy, ps2_read;
wire [7:0] rx_data;

reg [15:0] scan_code, key_down;
reg caps_lock, lshift, rshift;

wire [7:0] key_press = ascii(key_down, caps_lock, lshift || rshift);
assign out = { 8'b0, key_press };

localparam [2:0] idle            = 3'd0,
                 ack_wait        = 3'd1,
                 extended_key_up = 3'd2,
                 send_cmd        = 3'd3,
                 send_params     = 3'd4;

reg [2:0] state = idle;
reg [2:0] next_state;

ps2_device ps2 (
  .clk(clk),
  .ps2_clk(ps2_clk),
  .ps2_data(ps2_data),
  .write(ps2_write),
  .tx_data(tx_data),
  .read(ps2_read),
  .rx_data(rx_data),
  .busy(ps2_busy)
);

always @(posedge clk) begin
  ps2_write <= 0;

  if (ps2_read) begin
    scan_code <= { scan_code[7:0], rx_data };
  end

  case (state)
    idle: begin
      casez (scan_code)
        { EXTENDED, KEY_UP }: begin
          state <= extended_key_up;
        end

        { EXTENDED, 8'h?? }: begin
          key_down <= scan_code;
        end

        { KEY_UP, LEFT_SHIFT }: begin
          lshift <= 0;
        end

        { KEY_UP, RIGHT_SHIFT }: begin
          rshift <= 0;
        end

        { KEY_UP, 8'h?? }: begin
          if (scan_code[7:0] == key_down[7:0]) begin
            key_down <= 0;
          end
        end

        { 8'h??, LEFT_SHIFT }: begin
          lshift <= 1;
        end

        { 8'h??, RIGHT_SHIFT }: begin
          rshift <= 1;
        end

        { 8'h??, CAPS_LOCK }: begin
          if (key_down[7:0] != CAPS_LOCK) begin
            key_down <= CAPS_LOCK;
            caps_lock <= !caps_lock;

            // The lowest two bits represent Scroll Lock and Number Lock,
            // which we don't support and therefore always want to be off.
            cmd_params <= { !caps_lock, 2'b00 };
            tx_data <= CMD_SET_LEDS;

            state <= send_cmd;
          end
        end

        { 8'h??, SELF_TEST }: begin
          if (!ps2_busy) begin
            tx_data <= CMD_ENABLE;
            ps2_write <= 1;

            next_state <= idle;
            state <= ack_wait;
          end
        end

        { 8'h??, EXTENDED }, { 8'h??, KEY_UP }, { 8'h??, ACK }: begin
          // Do nothing, wait for the next byte.
        end

        default: begin
          key_down <= scan_code[7:0];
        end
      endcase
    end

    ack_wait: begin
      if (scan_code[7:0] == ACK) begin
        state <= next_state;
      end
    end

    extended_key_up: begin
      if (scan_code[15:8] == KEY_UP) begin
        state <= idle;

        if (key_down == { EXTENDED, scan_code[7:0] }) begin
          key_down <= 0;
        end
      end
    end

    send_cmd: begin
      if (!ps2_busy) begin
        ps2_write <= 1;
        next_state <= send_params;
        state <= ack_wait;
      end
    end

    send_params: begin
      if (!ps2_busy) begin
        tx_data <= cmd_params;
        ps2_write <= 1;
        state <= idle;
      end
    end
  endcase
end

function [7:0] ascii(input [15:0] key, input caps_lock, input shift);
  case (key)
    16'h01: ascii = 8'd149; // F9
    16'h03: ascii = 8'd145; // F5
    16'h04: ascii = 8'd143; // F3
    16'h05: ascii = 8'd141; // F1
    16'h06: ascii = 8'd142; // F2
    16'h07: ascii = 8'd152; // F12
    16'h09: ascii = 8'd150; // F10
    16'h0A: ascii = 8'd148; // F8
    16'h0B: ascii = 8'd146; // F6
    16'h0C: ascii = 8'd144; // F4
    16'h0D: ascii = "\t";
    16'h0E: ascii = shift ? "~" : "`";
    16'h15: ascii = (shift || caps_lock) ? "Q" : "q";
    16'h16: ascii = shift ? "!" : "1";
    16'h1A: ascii = (shift || caps_lock) ? "Z" : "z";
    16'h1B: ascii = (shift || caps_lock) ? "S" : "s";
    16'h1C: ascii = (shift || caps_lock) ? "A" : "a";
    16'h1D: ascii = (shift || caps_lock) ? "W" : "w";
    16'h1E: ascii = shift ? "@" : "2";
    16'h21: ascii = (shift || caps_lock) ? "C" : "c";
    16'h22: ascii = (shift || caps_lock) ? "X" : "x";
    16'h23: ascii = (shift || caps_lock) ? "D" : "d";
    16'h24: ascii = (shift || caps_lock) ? "E" : "e";
    16'h25: ascii = shift ? "$" : "4";
    16'h26: ascii = shift ? "#" : "3";
    16'h29: ascii = " ";
    16'h2A: ascii = (shift || caps_lock) ? "V" : "v";
    16'h2B: ascii = (shift || caps_lock) ? "F" : "f";
    16'h2C: ascii = (shift || caps_lock) ? "T" : "t";
    16'h2D: ascii = (shift || caps_lock) ? "R" : "r";
    16'h2E: ascii = shift ? "%" : "5";
    16'h31: ascii = (shift || caps_lock) ? "N" : "n";
    16'h32: ascii = (shift || caps_lock) ? "B" : "b";
    16'h33: ascii = (shift || caps_lock) ? "H" : "h";
    16'h34: ascii = (shift || caps_lock) ? "G" : "g";
    16'h35: ascii = (shift || caps_lock) ? "Y" : "y";
    16'h36: ascii = shift ? "^" : "6";
    16'h3A: ascii = (shift || caps_lock) ? "M" : "m";
    16'h3B: ascii = (shift || caps_lock) ? "J" : "j";
    16'h3C: ascii = (shift || caps_lock) ? "U" : "u";
    16'h3D: ascii = shift ? "&" : "7";
    16'h3E: ascii = shift ? "*" : "8";
    16'h41: ascii = shift ? "<" : ",";
    16'h42: ascii = (shift || caps_lock) ? "K" : "k";
    16'h43: ascii = (shift || caps_lock) ? "I" : "i";
    16'h44: ascii = (shift || caps_lock) ? "O" : "o";
    16'h45: ascii = shift ? ")" : "0";
    16'h46: ascii = shift ? "(" : "9";
    16'h49: ascii = shift ? ">" : ".";
    16'h4A: ascii = shift ? "?" : "/";
    16'h4B: ascii = (shift || caps_lock) ? "L" : "l";
    16'h4C: ascii = shift ? ";" : ":";
    16'h4D: ascii = (shift || caps_lock) ? "P" : "p";
    16'h4E: ascii = shift ? "_" : "-";
    16'h52: ascii = shift ? "\"" : "'";
    16'h54: ascii = shift ? "{" : "[";
    16'h55: ascii = shift ? "+" : "=";
    16'h5A: ascii = 8'd128; // Newline
    16'h5B: ascii = shift ? "}" : "]";
    16'h5D: ascii = shift ? "|" : "\\";
    16'h66: ascii = 8'd129; // Backspace
    16'h76: ascii = 8'd140; // Escape
    16'h78: ascii = 8'd151; // F11
    16'h83: ascii = 8'd147; // F7

    16'hE069: ascii = 8'd135; // End
    16'hE06B: ascii = 8'd130; // Left arrow
    16'hE06C: ascii = 8'd134; // Home
    16'hE070: ascii = 8'd138; // Insert
    16'hE071: ascii = 8'd139; // Delete
    16'hE072: ascii = 8'd133; // Down arrow
    16'hE074: ascii = 8'd132; // Right arrow
    16'hE075: ascii = 8'd131; // Up arrow
    16'hE07A: ascii = 8'd137; // Page down
    16'hE07D: ascii = 8'd136; // Page up

    default: ascii = 8'h00; // No key press
  endcase
endfunction

`endif

endmodule

module ps2_device (
  input clk,
  inout ps2_clk, ps2_data,
  input write,
  input [7:0] tx_data,
  output reg read,
  output reg [7:0] rx_data,
  output busy
);

localparam [0:255] PARITY = {
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

localparam [3:0] BITS_PER_FRAME = 4'd11;

localparam [3:0] idle                       = 4'd0,
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
                 tx_got_ack                 = 4'd12;

reg [3:0] state = idle;
assign busy = state != idle;

reg [3:0] rx_count = 0, tx_count = 0;
reg [10:0] frame;

reg [7:0] ps2_clk_debounce = 8'b10101010;
wire ps2_clk_high = ps2_clk_debounce[7:3] == 5'b11111;
wire ps2_clk_low  = ps2_clk_debounce[7:3] == 5'b00000;

wire ps2_clk_rx, ps2_data_rx;

reg ps2_clk_output_enable = 0;
reg ps2_data_output_enable = 0;

reg ps2_clk_output, ps2_data_output;

wire ps2_clk_tx = ps2_clk_output_enable ? ps2_clk_output : 0;
wire ps2_data_tx = ps2_data_output_enable ? ps2_data_output : 0;

reg delay_100us_enable, delay_20us_enable, delay_63clks_enable;
wire delay_100us_done, delay_20us_done, delay_63clks_done;

(* PULLUP_RESISTOR = "10K" *)
SB_IO #(
  .PIN_TYPE(6'b1010_00),
  .PULLUP(1)
) ps2_clk_io (
  .PACKAGE_PIN(ps2_clk),
  .INPUT_CLK(clk),
  .OUTPUT_CLK(clk),
  .OUTPUT_ENABLE(ps2_clk_output_enable),
  .D_IN_0(ps2_clk_rx),
  .D_OUT_0(ps2_clk_tx)
);

(* PULLUP_RESISTOR = "10K" *)
SB_IO #(
  .PIN_TYPE(6'b1010_00),
  .PULLUP(1)
) ps2_data_io (
  .PACKAGE_PIN(ps2_data),
  .INPUT_CLK(clk),
  .OUTPUT_CLK(clk),
  .OUTPUT_ENABLE(ps2_data_output_enable),
  .D_IN_0(ps2_data_rx),
  .D_OUT_0(ps2_data_tx)
);

delay #(
  .DURATION(12'd2513) // 100µs × 25.125MHz = 2512.2
) delay_100us (
  .clk(clk),
  .enable(delay_100us_enable),
  .done(delay_100us_done)
);

delay #(
  .DURATION(9'd503) // 20µs × 25.125MHz = 502.5
) delay_20us (
  .clk(clk),
  .enable(delay_20us_enable),
  .done(delay_20us_done)
);

delay #(
  .DURATION(6'd63)
) delay_63clks (
  .clk(clk),
  .enable(delay_63clks_enable),
  .done(delay_63clks_done)
);

always @(posedge clk) begin
  ps2_clk_debounce <= { ps2_clk_debounce[6:0], ps2_clk_rx };

  case (state)
    idle: begin
      read <= 0;
      rx_count <= 0;
      tx_count <= 0;

      // If the device pulls the clock line low, start receiving.
      if (ps2_clk_low) begin
        state <= rx_down_edge;
      end else if (write) begin
        // { STOP, PARITY, D7...D0 } (START bit has already been sent)
        frame <= { 1'b1, PARITY[tx_data], tx_data };
        state <= tx_force_clk_low;
      end
    end

    rx_clk_high: begin
      if (rx_count == BITS_PER_FRAME) begin
        // If the parity is incorrect, we still want to go back to the idle
        // state, but we won't output the message from the keyboard.
        if (frame[9] == PARITY[frame[8:1]]) begin
          rx_data <= frame[8:1];
          read <= 1;
        end

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

      if (delay_100us_done) begin
        delay_100us_enable <= 0;
        state <= tx_data_down;
      end
    end

    tx_data_down: begin
      ps2_data_output <= 0;
      ps2_data_output_enable <= 1;

      delay_20us_enable <= 1;

      if (delay_20us_done) begin
        delay_20us_enable <= 0;
        ps2_clk_output_enable <= 0;
        state <= tx_wait_first_down_edge;
      end
    end

    tx_wait_first_down_edge: begin
      delay_63clks_enable <= 1;

      if (delay_63clks_done && ps2_clk_low) begin
        delay_63clks_enable <= 0;
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
        // If ps2_data_rx is high, then we got an ack, otherwise we didn't.
        // However, retrying a transmission has not been implemented, so
        // we go back to the ack state either way.
        state <= tx_got_ack;
      end
    end

    tx_got_ack: begin
      if (ps2_clk_high) begin
        state <= idle;
      end
    end
  endcase
end

endmodule

module delay #(
  parameter DURATION = 0
) (
  input clk,
  input enable,
  output done
);

// Add 1 to ensure we maintain an upper bound if DURATION is a power of 2.
localparam BIT_LENGTH = $clog2(DURATION) + 1;

reg [(BIT_LENGTH - 1):0] count;
assign done = count == DURATION;

always @(posedge clk) begin
  if (enable) begin
    if (!done) begin
      count <= count + 1;
    end
  end else begin
    count <= 0;
  end
end

endmodule
