module Keyboard (
  input clk,
  inout ps2_clk, ps2_data,
  input btn1,
  output idle_out,
  output reg caps_lock,
  output [7:0] key_press,
);

localparam [7:0] LEFT_SHIFT   = 8'h12,
                 CAPS_LOCK    = 8'h58,
                 RIGHT_SHIFT  = 8'h59,
                 SELF_TEST    = 8'hAA,
                 CMD_SET_LEDS = 8'hED,
                 EXTENDED     = 8'hE0,
                 KEY_UP       = 8'hF0,
                 CMD_ENABLE   = 8'hF4,
                 ACK          = 8'hFA;

reg ps2_write = 0;
reg [7:0] tx_data;
reg [7:0] cmd_params;

wire ps2_busy;
assign idle_out = !ps2_busy;

wire ps2_read;
wire [7:0] rx_data;

localparam [2:0] idle = 3'd0,
                 wait_for_ack = 3'd1,
                 wait_for_extended_key_up = 3'd2,
                 send_cmd_with_params = 3'd3,
                 send_params = 3'd4;

reg [2:0] state = idle, next_state;

reg [15:0] scan_code, key_down;
reg lshift, rshift;

assign key_press = ascii(key_down, caps_lock, lshift || rshift);

ps2_receiver ps2 (
  .clk(clk),
  .ps2_clk(ps2_clk),
  .ps2_data(ps2_data),
  .write(ps2_write),
  .tx_data(tx_data),
  .read(ps2_read),
  .rx_data(rx_data),
  .busy(ps2_busy),
);

always @(posedge clk) begin
  ps2_write <= 0;

  if (ps2_read) begin
    scan_code <= { scan_code[7:0], rx_data } ;
  end

  case (state)
    idle: begin
      casez (scan_code)
        { EXTENDED, KEY_UP }: begin
          state <= wait_for_extended_key_up;
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

            tx_data <= CMD_SET_LEDS;
            cmd_params <= { !caps_lock, 2'b00 };

            state <= send_cmd_with_params;
          end
        end

        { 8'h??, SELF_TEST }: begin
          if (!ps2_busy) begin
            tx_data <= CMD_ENABLE;
            ps2_write <= 1;

            next_state <= idle;
            state <= wait_for_ack;
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

    wait_for_ack: begin
      if (scan_code[7:0] == ACK) begin
        state <= next_state;
      end
    end

    wait_for_extended_key_up: begin
      if (scan_code[15:8] == KEY_UP) begin
        state <= idle;

        if (key_down == { EXTENDED, scan_code[7:0] }) begin
          key_down <= 0;
        end
      end
    end

    send_cmd_with_params: begin
      if (!ps2_busy) begin
        ps2_write <= 1;
        next_state <= send_params;
        state <= wait_for_ack;
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
    16'h0E: ascii = shift ? "`" : "~";
    16'h1A: ascii = (shift || caps_lock) ? "Z" : "z";
    16'h15: ascii = (shift || caps_lock) ? "Q" : "q";
    16'h16: ascii = shift ? "!" : "1";
    16'h1B: ascii = (shift || caps_lock) ? "S" : "s";
    16'h1C: ascii = (shift || caps_lock) ? "A" : "a";
    16'h1D: ascii = (shift || caps_lock) ? "W" : "w";
    16'h1E: ascii = shift ? "@" : "2"; // Region-dependent
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
    16'h32: ascii = (shift || caps_lock) ? "B" : "b";
    16'h31: ascii = (shift || caps_lock) ? "N" : "n";
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
    16'h5D: ascii = shift ? "|" : "\\"; // Region-dependent
    16'h61: ascii = shift ? "~" : "#";  // Region-dependent
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

endmodule
