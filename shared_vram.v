module shared_vram (
  input clk,

  input rden,
  input [13:0] raddr,
  output reg [15:0] rdata,

  input wren,
  input [13:0] waddr,
  input [15:0] wdata,

  output reg wrack,
);

wire ram_wren = !rden && wren;

wire [13:0] ram_addr = rden ? raddr : wren ? waddr : 0;
wire [15:0] ram_din = ram_wren ? wdata : 0;
wire [15:0] ram_dout;

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
  if (rden) begin
    rdata <= ram_dout;
  end else if (wren && !wrack) begin
    wrack <= 1;
  end

  // Reset the write ACK signal if it was previously set
  if (wrack) begin
    wrack <= 0;
  end
end

endmodule
