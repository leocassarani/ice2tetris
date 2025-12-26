#include <unordered_map>
#include "snes.h"

const std::unordered_map<SDL_Scancode, uint16_t> scancodes = {
    { SDL_SCANCODE_B,      1 << 0  },
    { SDL_SCANCODE_Y,      1 << 1  },
    { SDL_SCANCODE_ESCAPE, 1 << 2  }, // Select
    { SDL_SCANCODE_RETURN, 1 << 3  }, // Start
    { SDL_SCANCODE_UP,     1 << 4  },
    { SDL_SCANCODE_DOWN,   1 << 5  },
    { SDL_SCANCODE_LEFT,   1 << 6  },
    { SDL_SCANCODE_RIGHT,  1 << 7  },
    { SDL_SCANCODE_A,      1 << 8  },
    { SDL_SCANCODE_X,      1 << 9  },
    { SDL_SCANCODE_L,      1 << 10 },
    { SDL_SCANCODE_R,      1 << 11 },
};

void SNES::key_down(SDL_Keysym& keysym)
{
    auto item = scancodes.find(keysym.scancode);

    if (item == scancodes.end())
        return;

    buttons |= item->second;
}

void SNES::key_up(SDL_Keysym& keysym)
{
    auto item = scancodes.find(keysym.scancode);

    if (item == scancodes.end())
        return;

    buttons &= !item->second;
}

void SNES::tick(uint8_t& snes_clk, uint8_t& snes_latch, uint8_t& snes_data)
{
    switch (state) {
    case SNESState::Idle:
        if (snes_latch) {
            state = SNESState::LatchHigh;
            snes_data = 0x01;
        }

        break;
    case SNESState::LatchHigh:
        if (!snes_latch && snes_clk) {
            state = SNESState::ClockHigh;
            snes_data = (buttons & 0x01) ? 0x00: 0x01;
        }

        break;
    case SNESState::ClockHigh:
        if (!snes_clk) {
            state = SNESState::ClockLow;
        }

        break;
    case SNESState::ClockLow:
        if (snes_clk) {
            if (++bit_count == 16) {
                snes_data = 0x00;
                bit_count = 0;
                state = SNESState::Idle;
            } else {
                snes_data = (buttons & (1 << bit_count)) ? 0x00 : 0x01;
                state = SNESState::ClockHigh;
            }
        }

        break;
    }
}
