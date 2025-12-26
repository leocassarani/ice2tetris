#ifndef SNES_H
#define SNES_H

#include <atomic>
#include <cstdint>
#include <SDL2/SDL.h>

enum class SNESState {
    Idle,
    LatchHigh,
    ClockHigh,
    ClockLow
};

class SNES {
public:
    void key_down(SDL_Keysym&);
    void key_up(SDL_Keysym&);
    void tick(uint8_t& snes_clk, uint8_t& snes_latch, uint8_t& snes_data);

private:
    SNESState state = SNESState::Idle;
    std::atomic<uint16_t> buttons = 0;
    uint8_t bit_count = 0;
};

#endif
