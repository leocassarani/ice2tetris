#include <arpa/inet.h>
#include <cstdio>
#include "flash.h"

// The program ROM starts at 1024KiB, so we want to ensure that the SPI master
// is trying to access the correct base address.
const uint32_t FlashBaseAddr = 0x100000;

Flash::Flash(const string& filename)
{
    file.open(filename, std::ifstream::binary);

    if (!file.is_open())
        std::perror("warning: couldn't open ROM file");
}

void Flash::tick(uint8_t spi_cs, uint8_t spi_clk, uint8_t spi_mosi, uint8_t& spi_miso)
{
    // The Chip Select (CS) signal is active low, so if it's high,
    // we can reset our state and bail out early.
    if (spi_cs) {
        state = FlashState::Idle;
        count = 0;
        return;
    }

    edge_detect(spi_clk);

    switch (state) {
    case FlashState::Idle:
        if (spi_posedge) {
            spi_read(spi_mosi);

            // Read the 8-bit command (which we expect to be 0x03).
            if (++count > 7) {
                if ((rbuf & 0x000000FF) == 0x03)
                    state = FlashState::Command;

                count = 0;
            }
        }

        break;
    case FlashState::Command:
        if (spi_posedge) {
            spi_read(spi_mosi);

            // Read the 24-bit flash address then start streaming data.
            if (++count > 23) {
                // Check that we get the expected address, abort otherwise.
                if ((rbuf & 0x00FFFFFF) == FlashBaseAddr) {
                    state = FlashState::Streaming;
                } else {
                    state = FlashState::Idle;
                }

                count = 0;
            }
        }

        break;
    case FlashState::Streaming:
        if (spi_negedge) {
            if (count == 0)
                fill_wbuf();

            spi_write(spi_miso);

            // Write 16 bits at a time before filling the write buffer with the
            // next word from the file on disk.
            if (++count > 15)
                count = 0;
        }

        break;
    }
}

void Flash::fill_wbuf()
{
    uint16_t instr;
    file.read(reinterpret_cast<char *>(&instr), 2);

    if (file.good()) {
        // Convert the 16-bit instruction from big-endian, which is how it's
        // stored on disk, to the endianness of the host that we're running on.
        wbuf = ntohs(instr);
    } else {
        // If we've reached past the end of the file, return 0xFFFF to mimic the
        // behaviour of the SPI flash chip.
        wbuf = 0xFFFF;
    }
}

void Flash::edge_detect(uint8_t spi_clk)
{
    spi_posedge = spi_clk && !spi_clk_prev;
    spi_negedge = !spi_clk && spi_clk_prev;
    spi_clk_prev = spi_clk;
}

void Flash::spi_read(uint8_t spi_mosi)
{
    rbuf = (spi_mosi & 0x01) | (rbuf << 1);
}

void Flash::spi_write(uint8_t& spi_miso)
{
    // We need to write the MSB first due to the on-disk layout of the ROM.
    spi_miso = 0x01 & (wbuf >> (15 - count));
}
