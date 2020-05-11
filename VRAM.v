`default_nettype none
`timescale 1ps / 1ps

module VRAM (
  input clk,

  input p_read,
  input [12:0] p_addr,

  input s_write,
  input [12:0] s_addr,
  input [15:0] s_din,

  output s_busy,
  output reg [15:0] p_dout,
  output reg [15:0] s_dout
);

assign s_busy = p_read;

reg ram_write;
reg [13:0] ram_addr;
reg [15:0] ram_din;
wire [15:0] ram_dout;

reg p_read_1, p_read_2;

SB_SPRAM256KA ram (
  .CLOCK(clk),
  .CHIPSELECT(1'b1),
  .ADDRESS(ram_addr),
  .WREN(ram_write),
  .MASKWREN(4'b1111),
  .DATAIN(ram_din),
  .STANDBY(1'b0),
  .SLEEP(1'b0),
  .POWEROFF(1'b1),
  .DATAOUT(ram_dout)
);

always @(posedge clk) begin
  ram_addr <= p_read ? p_addr : s_addr;
  ram_write <= !p_read && s_write;
  ram_din <= s_din;

  p_read_1 <= p_read;
  p_read_2 <= p_read_1;

  if (p_read_2) begin
    p_dout <= ram_dout;
  end else begin
    s_dout <= ram_dout;
  end
end

endmodule
