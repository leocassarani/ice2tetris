`default_nettype none

module ROM (
  input clk,
  input reset,

  input [15:0] address,
  output [15:0] instruction,
  output ready,

  input spi_miso,
  output spi_cs, output spi_sclk, output spi_mosi,
);

reg [15:0] ram_waddr = 0;
wire loading = ram_waddr < 16'h8000; // Read the first 32K addresses

assign ready = !loading;

wire ram_select = loading ? ram_waddr[14] : address[14];
wire [13:0] ram_addr = loading ? ram_waddr[13:0] : address[13:0];
wire [15:0] ram_din = loading ? flash_data : 16'b0;

wire [15:0] ram_data_lo, ram_data_hi;
assign instruction = loading ? 16'b0 : (ram_select ? ram_data_hi : ram_data_lo);

wire flash_ready;
wire ram_write = !reset && loading && flash_ready;

wire [23:0] flash_addr = 24'h100000 + { ram_waddr, 1'b0 }; // 1024KB + (addr << 1)
wire [15:0] flash_data;

SB_SPRAM256KA spram_lo (
  .CLOCK(clk),
  .CHIPSELECT(!ram_select),
  .ADDRESS(ram_addr),
  .WREN(ram_write),
  .MASKWREN(4'b1111),
  .DATAIN(ram_din),
  .STANDBY(1'b0),
  .SLEEP(1'b0),
  .POWEROFF(1'b1),
  .DATAOUT(ram_data_lo),
);

SB_SPRAM256KA spram_hi (
  .CLOCK(clk),
  .CHIPSELECT(ram_select),
  .ADDRESS(ram_addr),
  .WREN(ram_write),
  .MASKWREN(4'b1111),
  .DATAIN(ram_din),
  .STANDBY(1'b0),
  .SLEEP(1'b0),
  .POWEROFF(1'b1),
  .DATAOUT(ram_data_hi),
);

spi_flash_mem flash (
  .clk(clk),
  .clken(loading),
  .reset(reset),

  .raddr(flash_addr),
  .rdata(flash_data),
  .ready(flash_ready),

  .spi_cs(spi_cs),
  .spi_sclk(spi_sclk),
  .spi_mosi(spi_mosi),
  .spi_miso(spi_miso),
);

always @(posedge clk) begin
  if (ram_write) begin
    ram_waddr <= ram_waddr + 1;
  end
end

endmodule

module spi_flash_mem (
  input clk, clken, reset,
  input [23:0] raddr,

  output reg ready,
  output reg [15:0] rdata,

  output reg spi_cs, spi_sclk, spi_mosi,
  input spi_miso,
);

reg [7:0] buffer;
reg [3:0] xfer_cnt;
reg [2:0] state;

always @(posedge clk) begin
  ready <= 0;

  if (reset || ready || !clken) begin
    spi_cs <= 1;
    spi_sclk <= 1;
    xfer_cnt <= 0;
    state <= 0;
  end else begin
    spi_cs <= 0;

    if (xfer_cnt) begin
      if (spi_sclk) begin
        spi_sclk <= 0;
        spi_mosi <= buffer[7];
      end else begin
        spi_sclk <= 1;
        buffer <= { buffer, spi_miso };
        xfer_cnt <= xfer_cnt - 1;
      end
    end else begin
      case (state)
        0: begin
          buffer <= 'h03; // READ instruction
          xfer_cnt <= 8;
          state <= 1;
        end
        1: begin
          buffer <= raddr[23:16];
          xfer_cnt <= 8;
          state <= 2;
        end
        2: begin
          buffer <= raddr[15:8];
          xfer_cnt <= 8;
          state <= 3;
        end
        3: begin
          buffer <= raddr[7:0];
          xfer_cnt <= 8;
          state <= 4;
        end
        4: begin
          xfer_cnt <= 8;
          state <= 5;
        end
        5: begin
          rdata[15:8] <= buffer; // Big-endian
          xfer_cnt <= 8;
          state <= 6;
        end
        6: begin
          rdata[7:0] <= buffer;
          ready <= 1;
        end
      endcase
    end
  end
end

endmodule
