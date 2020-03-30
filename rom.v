`default_nettype none

module rom (
  input clk, clken,
  input [15:0] address,
  output [15:0] instruction,
  output ready,

  input spi_miso,
  output spi_cs, output spi_sclk, output spi_mosi,
);

reg [15:0] ram_waddr = 0;

// Read a total of 64KiB from flash, i.e. the first 32Ki 16-bit addresses.
wire loading = ram_waddr < 16'h8000;
assign ready = !loading;

wire ram_select_0 = loading ? ram_waddr[14] : address[14];
reg ram_select_1;

wire [13:0] ram_addr = loading ? ram_waddr[13:0] : address[13:0];
wire [15:0] ram_din = loading ? flash_data : 16'b0;
wire [15:0] ram_data_lo, ram_data_hi;

// We need to use the value of the ram_select signal from one clock cycle ago
// (ram_select_1) in order to deal with the one-clock delay between asking for
// a memory read and the relevant chip returning the contents of that address.
assign instruction = loading ? 16'b0 : (ram_select_1 ? ram_data_hi : ram_data_lo);

wire flash_ready;
wire ram_write = clken && loading && flash_ready;

wire [15:0] flash_data;

SB_SPRAM256KA spram_lo (
  .CLOCK(clk),
  .CHIPSELECT(!ram_select_0),
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
  .CHIPSELECT(ram_select_0),
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
  .clken(clken && loading),

  .raddr(24'h100000), // Start at 1024KiB.
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

  ram_select_1 <= ram_select_0;
end

endmodule

module spi_flash_mem (
  input clk, clken,
  input [23:0] raddr,

  output reg ready,
  output reg [15:0] rdata,

  input spi_miso,
  output reg spi_cs, spi_sclk, spi_mosi,
);

reg [15:0] buffer;
reg [4:0] count;
reg [1:0] state;

always @(posedge clk) begin
  ready <= 0;

  if (!clken) begin
    spi_cs <= 1;
    spi_sclk <= 1;
    count <= 0;
    state <= 0;
  end else begin
    spi_cs <= 0;

    if (count == 0) begin
      // Whenever we run out of bits to read or write, we need to reset the
      // count and fill up the buffer again.
      count <= 16;

      case (state)
        0: begin
          // Issue a Read Data (0x03) instruction, followed by the 8 MSB of
          // the 24-bit memory address we want to start reading from.
          buffer <= { 8'h03, raddr[23:16] };
          state <= 1;
        end

        1: begin
          // Write the remaining 16 bits of the memory address.
          buffer <= raddr[15:0];
          state <= 2;
        end

        2: begin
          // Fill the buffer with a 16-bit word, before moving on to the next
          // state, where we'll latch it into rdata.
          state <= 3;
        end

        3: begin
          // We've now read a 16-bit word so we can signal that it's ready to
          // be consumed. After the first read operation, we'll keep streaming
          // the rest of the flash memory, 16 bits at a time, until we're
          // stopped by the clken signal going low.
          rdata[15:0] <= buffer;
          ready <= 1;
        end
      endcase
    end else begin
      // Flip the clock signal every cycle to simulate a half-speed clock.
      spi_sclk <= ~spi_sclk;

      if (spi_sclk) begin
        // On the rising edge of the SPI clock, write the MSB of the buffer to
        // the flash SPI interface.
        spi_mosi <= buffer[15];
      end else begin
        // On the falling edge, read a bit from the SPI device and shift it
        // into the LSB of the buffer.
        buffer <= { buffer[14:0], spi_miso };
        count <= count - 1;
      end
    end
  end
end

endmodule
