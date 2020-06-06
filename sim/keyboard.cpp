#include "keyboard.h"
#include "ps2.h"

const int PulseWidth = 1064;

void Keyboard::key_down(SDL_Keysym& keysym)
{
    auto keycode = ps2_keycode(keysym.scancode);

    if (keycode) {
        std::lock_guard<std::mutex> lock(queue_mutex);

        if (keycode->extended)
            queue.push_back(0xE0);

        queue.push_back(keycode->code);
    }
}

void Keyboard::key_up(SDL_Keysym& keysym)
{
    auto keycode = ps2_keycode(keysym.scancode);

    if (keycode) {
        std::lock_guard<std::mutex> lock(queue_mutex);

        if (keycode->extended)
            queue.push_back(0xE0);

        queue.push_back(0xF0);
        queue.push_back(keycode->code);
    }
}

void Keyboard::tick(uint8_t& ps2_clk, uint8_t& ps2_data)
{
    if (wait-- > 0)
        return;

    std::lock_guard<std::mutex> lock(queue_mutex);

    switch (state) {
    case KeyboardState::Idle:
        ps2_clk = 1;
        ps2_data = 1;

        if (!queue.empty())
            state = KeyboardState::Sending;

        break;
    case KeyboardState::Sending:
        if (ps2_clk) {
            ps2_clk = 0;
            send_bit(ps2_data);
        } else {
            ps2_clk = 1;
        }

        break;
    }

    wait = PulseWidth;
}

// send_bit may only be called while holding queue_mutex.
void Keyboard::send_bit(uint8_t& ps2_data)
{
    if (bit_count == 0) {
        ps2_data = 0;
    } else if (bit_count < 9) {
        ps2_data = 0x01 & (queue.front() >> (bit_count - 1));
    } else if (bit_count == 9) {
        ps2_data = ps2_parity(queue.front());
    } else if (bit_count == 10) {
        ps2_data = 1;
        queue.pop_front();
        state = KeyboardState::Idle;
    }

    if (++bit_count > 10)
        bit_count = 0;
}
