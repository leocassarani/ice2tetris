`default_nettype none

module snes_controller (
  input clk,
  input snes_data,
  output reg snes_clk = 1'b1,
  output snes_latch,
  output [15:0] out
);

localparam [1:0] IDLE  = 2'd0,
                 LATCH = 2'd1,
                 DATA  = 2'd3;

reg [1:0] state = IDLE;
reg [3:0] cycles = 4'd0;

reg [15:0] buttons = 16'b0;
reg [7:0] keypress = 8'b0;
assign out = { 8'b0, keypress };

wire delay_6us_enable = state != IDLE, delay_6us_done;
wire delay_16ms_enable = state == IDLE, delay_16ms_done;

assign snes_latch = state == LATCH;

always @(posedge clk) begin
  case (state)
    IDLE: begin
      case (1'b1)
        buttons[0]:  keypress <= "B";
        buttons[1]:  keypress <= "Y";
        buttons[2]:  keypress <= 8'd140; // Escape
        buttons[3]:  keypress <= 8'd128; // Start
        buttons[4]:  keypress <= 8'd131; // Up arrow
        buttons[5]:  keypress <= 8'd133; // Down arrow
        buttons[6]:  keypress <= 8'd130; // Left arrow
        buttons[7]:  keypress <= 8'd132; // Right arrow
        buttons[8]:  keypress <= "A";
        buttons[9]:  keypress <= "X";
        buttons[10]: keypress <= "L";
        buttons[11]: keypress <= "R";
        default:     keypress <= 8'd0;
      endcase

      if (delay_16ms_done) begin
        cycles <= 4'd1;
        state <= LATCH;
      end
    end

    LATCH: begin
      if (delay_6us_done) begin
        // We want to keep the latch high for 2x 6µs cycles.
        if (cycles == 4'd0) begin
          cycles <= 4'd15;
          state <= DATA;
        end else begin
          cycles <= cycles - 4'd1;
        end
      end
    end

    DATA: begin
      if (delay_6us_done) begin
        if (snes_clk) begin
          buttons <= { ~snes_data, buttons[15:1] };
        end else begin
          if (cycles == 4'd0)
            state <= IDLE;
          else
            cycles <= cycles - 1;
        end

        snes_clk <= ~snes_clk;
      end
    end
  endcase
end

delay #(
  .DURATION(8'd151), // 6µs @ 25.125MHz = 150.75
  .CONTINUOUS(1'b1)
) delay_6us (
  .clk(clk),
  .enable(delay_6us_enable),
  .done(delay_6us_done)
);

delay #(
  .DURATION(19'd418_750), // 1/60Hz @ 25.125MHz = 418,750
  .CONTINUOUS(1'b1)
) delay_16ms (
  .clk(clk),
  .enable(1'b1),
  .done(delay_16ms_done)
);

endmodule
