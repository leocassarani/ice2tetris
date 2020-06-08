#include "flash.h"

void Flash::tick(uint8_t spi_cs, uint8_t spi_clk, uint8_t spi_mosi, uint8_t& spi_miso)
{
    // The Chip Select (CS) signal is active low, so if it's high,
    // we can reset our state and bail out early.
    if (spi_cs) {
        streaming = false;
        count = 0;
        return;
    }

    if (posedge(spi_clk)) {
        if (streaming) {
            if (count == 0) {
                std::string str;
                std::getline(file, str);

                if (file.good()) {
                    // Convert the string to an integer in base 2.
                    int i = std::stoi(str, nullptr, 2);
                    word = static_cast<uint16_t>(i);
                } else {
                    word = 0xFF;
                }
            }

            spi_miso = 0x01 & (word >> (15 - count));

            if (++count > 15)
                count = 0;
        } else {
            if (++count > 30) {
                count = 0;
                streaming = true;
            }
        }
    }
}

bool Flash::posedge(uint8_t spi_clk)
{
    bool posedge = spi_clk && !spi_clk_prev;
    spi_clk_prev = spi_clk;
    return posedge;
}
