#include <SDL2/SDL.h>
#include "verilated.h"

enum class ScanlineState {
    VISIBLE = 0,
    FRONT_PORCH,
    SYNC_PULSE,
    BACK_PORCH,
};

class VGA {
    public:
        VGA();
        ~VGA();

        void Start();
        void Tick(Uint8 vsync, Uint8 hsync, Uint8 red, Uint8 green, Uint8 blue);

    private:
        Uint8 *pixels;
        Uint32 userEvent;

        ScanlineState h_state, v_state;
        unsigned h_count, v_count;
        bool dirty;

        SDL_Window *window;
        SDL_Renderer *renderer;
        SDL_Texture *texture;
};
