`default_nettype none
`timescale 1ns / 1ps

module Computer_tb;

reg clk = 1;
wire flash_io0, flash_io1, flash_sck, flash_ssb;

initial begin
  $dumpfile("Computer_tb.vcd");
  $dumpvars(0, Computer_tb);
end

initial begin
  #10_000 $finish;
end

always begin
  #5 clk = !clk;
end

Computer #(
  .ROM_SIZE(8)
) computer (
  .CLK(clk),
  .BTN_N(1'b1),
  .FLASH_IO0(flash_io0),
  .FLASH_IO1(flash_io1),
  .FLASH_SCK(flash_sck),
  .FLASH_SSB(flash_ssb)
);

spi_flash_sim flash (
  .spi_cs(flash_ssb),
  .spi_sclk(flash_sck),
  .spi_mosi(flash_io0),
  .spi_miso(flash_io1)
);

endmodule

module spi_flash_sim (
  input spi_cs, spi_sclk, spi_mosi,
  output reg spi_miso = 0
);

reg [16:0] ROM [0:7];

initial begin
  $readmemb("program.hack", ROM);
end

reg [7:0] count = 0;

localparam IDLE = 1'd0,
           STREAM = 1'd1;

reg state = IDLE;

always @(posedge spi_sclk) begin
  if (!spi_cs) begin
    case (state)
      IDLE: begin
        if (count == 30) begin
          count <= 0;
          state <= STREAM;
        end else begin
          count <= count + 1;
        end
      end

      STREAM: begin
        spi_miso <= ROM[count[7:4]][15 - count[3:0]];
        count <= count + 1;
      end
    endcase
  end
end

endmodule
