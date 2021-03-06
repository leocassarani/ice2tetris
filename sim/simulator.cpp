#include <functional>
#include <thread>
#include "simulator.h"

Simulator::Simulator(TestBench<Vcomputer>& tb, const string& rom)
    : tb(tb),
      flash(Flash(rom))
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
            repaint();
            break;
        case SDL_KEYDOWN:
        case SDL_KEYUP:
            key_press(e.key);
            break;
        case SDL_QUIT:
            exit = true;
            break;
        }
    }
}

void Simulator::repaint()
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

void Simulator::key_press(const SDL_KeyboardEvent& e)
{
    auto keysym = e.keysym;
    auto pressed = e.state == SDL_PRESSED;

    if (keysym.mod & (KMOD_CTRL | KMOD_GUI)) {
        switch (keysym.sym) {
        case SDLK_r:
            // Cmd+R or Ctrl+R will simulate pressing the reset button.
            reset = pressed;
            break;
        }
    } else if (pressed) {
        keyboard.key_down(keysym);
    } else {
        keyboard.key_up(keysym);
    }
}

inline uint8_t vga_color(uint8_t a, uint8_t b, uint8_t c, uint8_t d)
{
    return 0x0F & (a << 3 | b << 2 | c << 1 | d);
}

void Simulator::simulate()
{
    while (!exit) {
        tb.core.RESET_N = !reset;
        tb.tick();

        flash.tick(
            tb.core.FLASH_CS,
            tb.core.FLASH_CLK,
            tb.core.FLASH_MOSI,
            tb.core.FLASH_MISO
        );

        keyboard.tick(
            tb.core.PS2_CLK,
            tb.core.PS2_DATA
        );

        vga.tick(
            tb.core.P1B7,
            tb.core.P1B8,
            vga_color(tb.core.P1A4, tb.core.P1A3, tb.core.P1A2, tb.core.P1A1),
            vga_color(tb.core.P1B4, tb.core.P1B3, tb.core.P1B2, tb.core.P1B1),
            vga_color(tb.core.P1A10, tb.core.P1A9, tb.core.P1A8, tb.core.P1A7)
        );
    }
}
