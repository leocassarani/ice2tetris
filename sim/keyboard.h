#ifndef KEYBOARD_H
#define KEYBOARD_H

#include <SDL2/SDL.h>
#include <deque>
#include <mutex>

enum class KeyboardState {
    Idle,
    Sending
};

class Keyboard {
public:
    void key_down(SDL_Keysym&);
    void key_up(SDL_Keysym&);
    void tick(uint8_t& ps2_clk, uint8_t& ps2_data);

private:
    KeyboardState state = KeyboardState::Idle;

    std::deque<uint8_t> queue;
    std::mutex queue_mutex;

    uint8_t bit_count = 0;
    int wait = 0;

    void send_bit(uint8_t& ps2_data);
};

#endif
