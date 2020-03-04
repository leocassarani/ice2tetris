`default_nettype none

module ROM (
  input clk,
  input reset,

  input [13:0] raddr,
  output [15:0] rdata,
  output ready,

  input spi_miso,
  output spi_cs, output spi_sclk, output spi_mosi,
);

wire [15:0] flash_out;

reg [15:0] waddr = 0;
wire loading = waddr < 16'h4000;

assign ready = !loading;

wire flash_ready;
wire ram_write = !reset && loading && flash_ready;

wire [23:0] flash_raddr = 24'h100000 + { waddr, 1'b0 };

SB_SPRAM256KA spram (
  .CLOCK(clk),
  .CHIPSELECT(1'b1),
  .ADDRESS(loading ? waddr[13:0] : raddr),
  .WREN(ram_write),
  .MASKWREN(4'b1111),
  .DATAIN(loading ? flash_out : 16'b0),
  .STANDBY(1'b0),
  .SLEEP(1'b0),
  .POWEROFF(1'b1),
  .DATAOUT(rdata),
);

spi_flash_mem flash (
  .clk(clk),
  .clken(loading),
  .reset(reset),

  .raddr(flash_raddr),
  .rdata(flash_out),
  .ready(flash_ready),

  .spi_cs(spi_cs),
  .spi_sclk(spi_sclk),
  .spi_mosi(spi_mosi),
  .spi_miso(spi_miso),
);

always @(posedge clk) begin
  if (ram_write) begin
    waddr <= waddr + 1;
  end
end

endmodule

module spi_flash_mem (
  input clk,
  input clken, reset,
  input [23:0] raddr,

  output reg ready,
  output reg [15:0] rdata,

  output reg spi_cs, spi_sclk, spi_mosi,
  input spi_miso,
);

reg [7:0] buffer;
reg [3:0] xfer_cnt;
reg [2:0] state = 0;

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
