#include <stdio.h>
#include "vga.h"

#define SCREEN_WIDTH  640
#define SCREEN_HEIGHT 480

VGA::VGA()
    : h_state(ScanlineState::FRONT_PORCH),
      v_state(ScanlineState::VISIBLE),
      dirty(false)
{
    pixels = new Uint8[3 * SCREEN_WIDTH * SCREEN_HEIGHT];
    memset(pixels, 0xFF, 3 * SCREEN_WIDTH * SCREEN_HEIGHT);
    userEvent = SDL_RegisterEvents(1);
}

VGA::~VGA() {
    delete[] pixels;
    SDL_DestroyTexture(texture);
    SDL_DestroyRenderer(renderer);
    SDL_DestroyWindow(window);
    SDL_Quit();
}

void VGA::Start() {
    SDL_Init(SDL_INIT_VIDEO);

    window = SDL_CreateWindow("VGA", SDL_WINDOWPOS_CENTERED, SDL_WINDOWPOS_CENTERED, SCREEN_WIDTH, SCREEN_HEIGHT, SDL_WINDOW_SHOWN);
    renderer = SDL_CreateRenderer(window, -1, 0);
    texture = SDL_CreateTexture(renderer, SDL_PIXELFORMAT_RGB24, SDL_TEXTUREACCESS_STATIC, SCREEN_WIDTH, SCREEN_HEIGHT);

    SDL_Event e;
    bool exit = false;

    while (!exit) {
        SDL_WaitEvent(&e);

        switch (e.type) {
            case SDL_QUIT:
                exit = true;
                break;
        }

        if (e.type == userEvent) {
            SDL_UpdateTexture(texture, NULL, pixels, 3 * SCREEN_WIDTH);
            SDL_RenderClear(renderer);
            SDL_RenderCopy(renderer, texture, NULL, NULL);
            SDL_RenderPresent(renderer);
        }
    }
}

void VGA::Tick(Uint8 hsync, Uint8 vsync, Uint8 red, Uint8 green, Uint8 blue) {
    h_count++;

    switch (h_state) {
        case ScanlineState::VISIBLE:
            if (h_count == 640) {
                h_state = ScanlineState::FRONT_PORCH;
                h_count = 0;
                v_count++;
            }
            break;
        case ScanlineState::FRONT_PORCH:
            if (!hsync) {
                h_state = ScanlineState::SYNC_PULSE;
                h_count = 0;
            }
            break;
        case ScanlineState::SYNC_PULSE:
            if (hsync) {
                h_state = ScanlineState::BACK_PORCH;
                h_count = 0;
            }
            break;
        case ScanlineState::BACK_PORCH:
            if (h_count == 48) {
                h_count = 0;
                h_state = ScanlineState::VISIBLE;
            }
            break;
    }

    switch (v_state) {
        case ScanlineState::VISIBLE:
            if (v_count == 480) {
                v_state = ScanlineState::FRONT_PORCH;
                v_count = 0;
            }
            break;
        case ScanlineState::FRONT_PORCH:
            if (!vsync) {
                v_state = ScanlineState::SYNC_PULSE;
                v_count = 0;
            }
            break;
        case ScanlineState::SYNC_PULSE:
            if (vsync) {
                v_state = ScanlineState::BACK_PORCH;
                v_count = 0;
            }
            break;
        case ScanlineState::BACK_PORCH:
            if (v_count == 33) {
                v_state = ScanlineState::VISIBLE;
                v_count = 0;
            }
            break;
    }

    if (h_state == ScanlineState::VISIBLE && v_state == ScanlineState::VISIBLE) {
        int i = 3 * (h_count + (v_count * SCREEN_WIDTH));
        pixels[i++] = red * 0xFF;
        pixels[i++] = green * 0xFF;
        pixels[i]   = blue * 0xFF;
        dirty = true;
    } else if (dirty) {
        SDL_Event event = { .type = userEvent };
        SDL_PushEvent(&event);
        dirty = false;
    }
}
