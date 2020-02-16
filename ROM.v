module ROM (
  input clk,
  input [13:0] address,
  output ready,
  output [15:0] out,
  output led,

  output spi_cs, output spi_sclk, output spi_mosi,
  input spi_miso,
);

reg reset = 1;

wire flash_read;
wire [15:0] flash_out;
wire [15:0] flash_offset;

reg [15:0] flash_rdata;

wire ram_write = flash_offset < 16'h4000;
assign ready = !ram_write;

assign led = !flash_read;

SB_SPRAM256KA spram (
  .CLOCK(clk),
  .CHIPSELECT(1'b1),
  .ADDRESS(ram_write ? flash_offset[13:0] : address),
  .WREN(ram_write),
  .MASKWREN(4'b1111),
  .DATAIN(ram_write ? flash_rdata : 16'b0),
  .STANDBY(1'b0),
  .SLEEP(1'b0),
  .POWEROFF(1'b1),
  .DATAOUT(out),
);

spi_flash_mem flash (
  .clk(clk),
  .reset(reset),
  .enabled(ram_write),
  .address(24'h100000),

  .read(flash_read),
  .rdata(flash_out),
  .offset(flash_offset),

  .spi_cs(spi_cs),
  .spi_sclk(spi_sclk),
  .spi_mosi(spi_mosi),
  .spi_miso(spi_miso),
);

always @(posedge clk) begin
  reset <= 0;
end

always @(posedge flash_read) begin
  flash_rdata <= flash_out;
end

endmodule

module spi_flash_mem (
  input clk,
  input reset, enabled,
  input [23:0] address,

  output reg read,
  output reg [15:0] rdata,
  output reg [15:0] offset,

  input spi_miso,
  output reg spi_cs, spi_sclk, spi_mosi,
);

initial begin
  offset = 0;
end

reg [7:0] buffer;
reg [3:0] xfer_cnt = 0;
reg [2:0] state = 0;

always @(posedge clk) begin
  read <= 0;

  if (reset || !enabled) begin
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
          buffer <= 8'h03; // READ instruction
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
          rdata[15:8] <= buffer;
          xfer_cnt <= 8;
          state <= 6;
        end

        6: begin
          rdata[7:0] <= buffer;
          offset <= offset + 1;
          read <= 1;

          xfer_cnt <= 8;
          state <= 5;
        end
      endcase
    end
  end
end

endmodule
