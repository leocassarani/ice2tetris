#ifndef VGA_H
#define VGA_H

#include <memory>
#include <vector>
#include <SDL2/SDL.h>

using std::vector;

enum class ScanlineState {
    Visible,
    FrontPorch,
    SyncPulse,
    BackPorch,
};

class VGA {
    public:
        VGA();
        ~VGA();

        void run();
        void tick(uint8_t vsync, uint8_t hsync, uint8_t red, uint8_t green, uint8_t blue);
        uint8_t key_pressed();

    private:
        void key_down(const SDL_KeyboardEvent&);
        void key_up(const SDL_KeyboardEvent&);
        SDL_Keycode key_code;

        vector<uint16_t> pixels;
        uint32_t event_type;

        ScanlineState h_state = ScanlineState::FrontPorch;
        ScanlineState v_state = ScanlineState::Visible;

        unsigned h_count = 0, v_count = 0;
        bool dirty = false;

        std::unique_ptr<SDL_Window, void(*)(SDL_Window *)> window{nullptr, nullptr};
        std::unique_ptr<SDL_Renderer, void(*)(SDL_Renderer *)> renderer{nullptr, nullptr};
        std::unique_ptr<SDL_Texture, void(*)(SDL_Texture *)> texture{nullptr, nullptr};
};

#endif
