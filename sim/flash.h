#ifndef FLASH_H
#define FLASH_H

#include <fstream>
#include <string>

using std::string;

enum class FlashState {
    Idle,
    Command,
    Streaming,
};

class Flash {
public:
    Flash(const string& filename)
        : file(std::ifstream(filename)) {};

    void tick(uint8_t spi_cs, uint8_t spi_clk, uint8_t spi_mosi, uint8_t& spi_miso);

private:
    std::ifstream file;
    FlashState state = FlashState::Idle;

    unsigned count = 0;

    void edge_detect(uint8_t spi_clk);
    uint8_t spi_clk_prev = 0;

    bool spi_posedge = false;
    bool spi_negedge = false;

    void spi_read(uint8_t spi_mosi);
    void spi_write(uint8_t& spi_miso);

    uint32_t rbuf;
    uint16_t wbuf;

    void fill_wbuf();
};

#endif
