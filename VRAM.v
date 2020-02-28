module VRAM (
  input clk,
  input reset,

  input rden,
  input [13:0] raddr,

  input wren,
  input [13:0] waddr,
  input [15:0] wdata,
  output reg wrack,

  output loaded,
  output reg [15:0] out,

  input spi_miso,
  output spi_cs, output spi_sclk, output spi_mosi,
);

reg [15:0] rom_raddr = 0;
reg [15:0] ram_waddr = 0;

wire loading = rom_raddr < 16'h4000;
assign loaded = !loading;

wire ram_write = !reset && loading && rom_ready;

wire rom_ready;
wire [15:0] rom_out;

reg [13:0] ram_raddr;
wire [15:0] ram_out;

reg ram_wren;
reg [1:0] state = 0;

reg [15:0] ram_wdata;

wire [13:0] ram_addr = loading ? (
  rom_raddr[13:0]
) : (
  ram_wren ? ram_waddr : ram_raddr
);

wire [15:0] ram_din = loading ? (
  rom_out
) : (
  ram_wren ? ram_wdata : 16'b0
);

ROM rom (
  .clk(clk),
  .reset(reset),
  .address(rom_raddr),
  .out(rom_out),
  .ready(rom_ready),

  .spi_cs(spi_cs),
  .spi_sclk(spi_sclk),
  .spi_mosi(spi_mosi),
  .spi_miso(spi_miso),
);

SB_SPRAM256KA spram (
  .CLOCK(clk),
  .CHIPSELECT(1'b1),
  .ADDRESS(ram_addr),
  .WREN(ram_write || ram_wren),
  .MASKWREN(4'b1111),
  .DATAIN(ram_din),
  .STANDBY(1'b0),
  .SLEEP(1'b0),
  .POWEROFF(1'b1),
  .DATAOUT(ram_out),
);

always @(posedge clk) begin
  if (ram_write) begin
    rom_raddr <= rom_raddr + 1;
  end else begin
    wrack <= 1'b0;

    case (state)
      0: begin
        if (rden) begin
          ram_raddr <= raddr;
          state <= 1;
        end else if (wren) begin
          ram_waddr <= waddr;
          ram_wdata <= wdata;
          ram_wren <= 1'b1;
          state <= 2;
        end
      end

      1: begin
        out <= ram_out;

        if (rden) begin
          ram_raddr <= raddr;
        end else begin
          state <= 0;
        end
      end

      2: begin
        ram_wren <= 1'b0;
        wrack <= 1'b1;

        if (rden) begin
          ram_raddr <= raddr;
          state <= 1;
        end
      end
    endcase
  end
end

endmodule
