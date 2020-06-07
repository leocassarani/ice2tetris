#include <functional>
#include <thread>
#include "simulator.h"

Simulator::Simulator(TestBench<Vcomputer>& tb) : tb(tb)
{
    SDL_Init(SDL_INIT_VIDEO);

    window = {
        SDL_CreateWindow(
            "VGA (640 x 480 @ 60MHz)",
            SDL_WINDOWPOS_CENTERED,
            SDL_WINDOWPOS_CENTERED,
            ScreenWidth,
            ScreenHeight,
            SDL_WINDOW_SHOWN | SDL_WINDOW_RESIZABLE
        ),
        SDL_DestroyWindow
    };

    renderer = {
        SDL_CreateRenderer(window.get(), -1, 0),
        SDL_DestroyRenderer
    };

    SDL_RenderSetLogicalSize(renderer.get(), ScreenWidth, ScreenHeight);

    texture = {
        SDL_CreateTexture(renderer.get(), SDL_PIXELFORMAT_RGB444, SDL_TEXTUREACCESS_STREAMING, ScreenWidth, ScreenHeight),
        SDL_DestroyTexture
    };

    vga.display = [] {
        SDL_Event event = { .type = SDL_USEREVENT };
        SDL_PushEvent(&event);
    };
}

Simulator::~Simulator()
{
    SDL_Quit();
}

void Simulator::run()
{

    std::thread thread(&Simulator::simulate, this);
    event_loop();
    thread.join();
}

void Simulator::event_loop()
{
    SDL_Event e;

    while (!exit) {
        SDL_WaitEvent(&e);

        switch (e.type) {
        case SDL_USEREVENT:
            {
                void *pixels;
                int pitch;

                SDL_LockTexture(texture.get(), nullptr, &pixels, &pitch);
                vga.draw(static_cast<uint16_t *>(pixels));
                SDL_UnlockTexture(texture.get());

                SDL_RenderClear(renderer.get());
                SDL_RenderCopy(renderer.get(), texture.get(), nullptr, nullptr);
                SDL_RenderPresent(renderer.get());
            }
            break;
        case SDL_KEYDOWN:
            keyboard.key_down(e.key.keysym);
            break;
        case SDL_KEYUP:
            keyboard.key_up(e.key.keysym);
            break;
        case SDL_QUIT:
            exit = true;
            break;
        }
    }
}

void Simulator::simulate()
{
    while (!exit) {
        tb.tick();

        keyboard.tick(
            tb.core.PS2_CLK,
            tb.core.PS2_DATA
        );

        vga.tick(
            tb.core.P1B7,
            tb.core.P1B8,
            tb.core.P1A4  << 3 | tb.core.P1A3 << 2 | tb.core.P1A2 << 1 | tb.core.P1A1,
            tb.core.P1B4  << 3 | tb.core.P1B3 << 2 | tb.core.P1B2 << 1 | tb.core.P1B1,
            tb.core.P1A10 << 3 | tb.core.P1A9 << 2 | tb.core.P1A8 << 1 | tb.core.P1A7
        );
    }
}
