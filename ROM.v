module ROM (
  input clk,
  input [15:0] address,
  output ready,
  output [15:0] out,

  output spi_cs, output spi_sclk, output spi_mosi,
  input spi_miso,
);

reg reset = 1;

wire [15:0] flash_data;
wire [23:0] flash_addr = 24'h100000 + { address, 1'b0 }; // 1024KB + (addr << 1);

always @(posedge clk) begin
  if (reset > 0) begin
    reset <= reset - 1;
  end
end

spi_flash_mem flash (
  .clk(clk),
  .reset(reset),
  .address(flash_addr),
  .rdata(out),
  .ready(ready),

  .spi_cs(spi_cs),
  .spi_sclk(spi_sclk),
  .spi_mosi(spi_mosi),
  .spi_miso(spi_miso),
);

endmodule

module spi_flash_mem (
  input clk, reset,
  input [23:0] address,

  output reg ready = 0,
  output reg [15:0] rdata,

  output reg spi_cs, spi_sclk, spi_mosi,
  input spi_miso,
);

reg [7:0] buffer;
reg [3:0] xfer_cnt;
reg [2:0] state;

always @(posedge clk) begin
  ready <= 0;

  if (reset || ready) begin
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
          buffer <= address[23:16];
          xfer_cnt <= 8;
          state <= 2;
        end
        2: begin
          buffer <= address[15:8];
          xfer_cnt <= 8;
          state <= 3;
        end
        3: begin
          buffer <= address[7:0];
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
