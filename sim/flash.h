#ifndef FLASH_H
#define FLASH_H

#include <fstream>
#include <string>

class Flash {
public:
    Flash(const std::string& filename)
        : file(std::ifstream(filename)) {};

    void tick(uint8_t spi_cs, uint8_t spi_clk, uint8_t spi_mosi, uint8_t& spi_miso);

private:
    std::ifstream file;

    uint8_t spi_clk_prev = 0;
    bool posedge(uint8_t spi_clk);

    bool streaming = false;
    unsigned count = 0;
    uint16_t word = 0;
};

#endif
