module Keyboard (
  input clk,
  inout ps2_clk, ps2_data,
  input btn1,
  output idle_out,
  output [7:0] key_press,
);

reg ps2_write = 0;
reg [7:0] tx_data;

wire ps2_busy;
assign idle_out = !ps2_busy;

wire ps2_read;
wire [7:0] rx_data;

localparam [1:0] idle = 2'd0,
                 wait_for_ack = 2'd1,
                 wait_for_key_up = 2'd2;

reg [1:0] state = idle;

reg [7:0] scan_code;
reg [15:0] key_down;

assign key_press = ascii(key_down);

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
  if (ps2_read) begin
    scan_code <= rx_data;
  end

  case (state)
    idle: begin
      case (scan_code)
        8'hAA: begin
          if (!ps2_busy) begin
            tx_data <= 8'hF4;
            ps2_write <= 1;
            state <= wait_for_ack;
          end
        end

        8'hF0: begin
          state <= wait_for_key_up;
        end

        default: begin
          key_down <= scan_code;
        end
      endcase
    end

    wait_for_ack: begin
      ps2_write <= 0;

      if (scan_code == 8'hFA) begin
        state <= idle;
      end
    end

    wait_for_key_up: begin
      if (scan_code == key_down) begin
        key_down <= 0;
      end

      if (scan_code != 8'hF0) begin
        scan_code <= 0;
        state <= idle;
      end
    end
  endcase
end

function [7:0] ascii(input [15:0] key);
  case (key)
    16'h0E: ascii = "`";
    16'h1A: ascii = "z";
    16'h15: ascii = "q";
    16'h16: ascii = "1";
    16'h1B: ascii = "s";
    16'h1C: ascii = "a";
    16'h1D: ascii = "w";
    16'h1E: ascii = "2";
    16'h21: ascii = "c";
    16'h22: ascii = "x";
    16'h23: ascii = "d";
    16'h24: ascii = "e";
    16'h25: ascii = "4";
    16'h26: ascii = "3";
    16'h29: ascii = " ";
    16'h2A: ascii = "v";
    16'h2B: ascii = "f";
    16'h2C: ascii = "t";
    16'h2D: ascii = "r";
    16'h2E: ascii = "5";
    16'h32: ascii = "b";
    16'h31: ascii = "n";
    16'h33: ascii = "h";
    16'h34: ascii = "g";
    16'h35: ascii = "y";
    16'h36: ascii = "6";
    16'h3A: ascii = "m";
    16'h3B: ascii = "j";
    16'h3C: ascii = "u";
    16'h3D: ascii = "7";
    16'h3E: ascii = "8";
    16'h41: ascii = ",";
    16'h42: ascii = "k";
    16'h43: ascii = "i";
    16'h44: ascii = "o";
    16'h45: ascii = "0";
    16'h46: ascii = "9";
    16'h49: ascii = ".";
    16'h4A: ascii = "/";
    16'h4B: ascii = "l";
    16'h4C: ascii = ";";
    16'h4D: ascii = "p";
    16'h4E: ascii = "-";
    16'h52: ascii = "'";
    16'h54: ascii = "[";
    16'h55: ascii = "=";
    16'h5B: ascii = "]";
    16'h5D: ascii = "\\";   // Region-dependent
    16'h61: ascii = "#";    // Region-dependent
    default: ascii = 8'h00; // No key press
  endcase
endfunction

endmodule
