#ifndef VGA_H
#define VGA_H

#include <functional>
#include <vector>
#include <SDL2/SDL.h>

const int ScreenWidth  = 640;
const int ScreenHeight = 480;

enum class ScanlineState {
    Visible,
    FrontPorch,
    SyncPulse,
    BackPorch,
};

class VGA {
    public:
        VGA();
        void tick(uint8_t vsync, uint8_t hsync, uint8_t red, uint8_t green, uint8_t blue);

        std::function<void()> display;
        std::vector<uint16_t> pixels;

    private:
        ScanlineState h_state = ScanlineState::FrontPorch;
        ScanlineState v_state = ScanlineState::Visible;

        unsigned h_count = 0, v_count = 0;
        bool dirty = false;

        inline bool h_visible() const
        {
            return h_state == ScanlineState::Visible;
        }

        inline bool v_visible() const
        {
            return v_state == ScanlineState::Visible;
        }
};

#endif
