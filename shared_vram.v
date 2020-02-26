module shared_vram (
  input clk,
  input reset,

  input rden,
  input [13:0] raddr,
  output reg [15:0] rdata,

  input wren,
  input [13:0] waddr,
  input [15:0] wdata,

  output reg wrack,
);

reg [13:0] ram_addr = 0;
reg [15:0] ram_din = 0;
wire [15:0] ram_dout;
reg ram_wren = 0;

reg [1:0] state = 0;

SB_SPRAM256KA spram (
  .CLOCK(clk),
  .CHIPSELECT(1'b1),
  .ADDRESS(ram_addr),
  .WREN(ram_wren),
  .MASKWREN(4'b1111),
  .DATAIN(ram_din),
  .STANDBY(1'b0),
  .SLEEP(1'b0),
  .POWEROFF(1'b1),
  .DATAOUT(ram_dout),
);

always @(posedge clk) begin
  if (!reset) begin
    wrack <= 1'b0;

    case (state)
      0: begin
        if (rden) begin
          ram_addr <= raddr;
          ram_din <= 16'b0;
          ram_wren <= 1'b0;
          state <= 1;
        end else if (wren) begin
          ram_addr <= waddr;
          ram_din <= wdata;
          ram_wren <= 1'b1;
          state <= 3;
        end
      end

      1: begin
        state <= 2;
      end

      2: begin
        rdata <= ram_dout;

        if (rden) begin
          ram_addr <= raddr;
          ram_din <= 16'b0;
          ram_wren <= 1'b0;
          state <= 1;
        end else begin
          state <= 0;
        end
      end

      3: begin
        ram_wren <= 1'b0;
        wrack <= 1'b1;

        if (rden) begin
          ram_addr <= raddr;
          ram_din <= 16'b0;
          state <= 1;
        end else begin
          state <= 0;
        end
      end
    endcase
  end
end

endmodule
