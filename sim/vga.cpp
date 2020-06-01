#include "vga.h"

const int ScreenWidth = 640;
const int ScreenHeight = 480;

VGA::VGA()
{
    pixels.assign(3 * ScreenWidth * ScreenHeight, 0xFF);
    event_type = SDL_RegisterEvents(1);
}

VGA::~VGA()
{
    SDL_Quit();
}

void VGA::run()
{
    SDL_Init(SDL_INIT_VIDEO);

    window = {
        SDL_CreateWindow(
            "VGA (640 x 480 @ 60MHz)",
            SDL_WINDOWPOS_CENTERED,
            SDL_WINDOWPOS_CENTERED,
            ScreenWidth,
            ScreenHeight,
            SDL_WINDOW_SHOWN
        ),
        SDL_DestroyWindow
    };

    renderer = {
        SDL_CreateRenderer(window.get(), -1, 0),
        SDL_DestroyRenderer
    };

    texture = {
        SDL_CreateTexture(renderer.get(), SDL_PIXELFORMAT_RGB24, SDL_TEXTUREACCESS_STATIC, ScreenWidth, ScreenHeight),
        SDL_DestroyTexture
    };

    bool exit = false;
    SDL_Event e;

    while (!exit) {
        SDL_WaitEvent(&e);

        if (e.type == event_type) {
            SDL_UpdateTexture(texture.get(), NULL, pixels.data(), 3 * ScreenWidth);
            SDL_RenderClear(renderer.get());
            SDL_RenderCopy(renderer.get(), texture.get(), NULL, NULL);
            SDL_RenderPresent(renderer.get());
        } else {
            switch (e.type) {
                case SDL_KEYDOWN:
                    key_down(e.key);
                    break;
                case SDL_KEYUP:
                    key_up(e.key);
                    break;
                case SDL_QUIT:
                    exit = true;
                    break;
            }
        }
    }
}

void VGA::key_down(const SDL_KeyboardEvent& event)
{
    key_code = event.keysym.sym;
}

void VGA::key_up(const SDL_KeyboardEvent& event)
{
    if (key_code == event.keysym.sym)
        key_code = 0;
}

uint8_t VGA::key_pressed()
{
    switch (key_code) {
    case SDLK_LEFT:
        return 130;
    case SDLK_UP:
        return 131;
    case SDLK_RIGHT:
        return 132;
    case SDLK_DOWN:
        return 133;
    case SDLK_RETURN:
        return 128;
    case SDLK_ESCAPE:
        return 140;
    default:
        return 0;
    }
}

void VGA::tick(uint8_t hsync, uint8_t vsync, uint8_t red, uint8_t green, uint8_t blue)
{
    h_count++;

    switch (h_state) {
        case ScanlineState::Visible:
            if (h_count == ScreenWidth) {
                h_state = ScanlineState::FrontPorch;
                v_count++;
            }
            break;
        case ScanlineState::FrontPorch:
            if (!hsync) {
                h_state = ScanlineState::SyncPulse;
            }
            break;
        case ScanlineState::SyncPulse:
            if (hsync) {
                h_state = ScanlineState::BackPorch;
                h_count = 0;
            }
            break;
        case ScanlineState::BackPorch:
            if (h_count == 48) {
                h_state = ScanlineState::Visible;
                h_count = 0;
            }
            break;
    }

    switch (v_state) {
        case ScanlineState::Visible:
            if (v_count == ScreenHeight) {
                v_state = ScanlineState::FrontPorch;
            }
            break;
        case ScanlineState::FrontPorch:
            if (!vsync) {
                v_state = ScanlineState::SyncPulse;
            }
            break;
        case ScanlineState::SyncPulse:
            if (vsync) {
                v_state = ScanlineState::BackPorch;
                v_count = 0;
            }
            break;
        case ScanlineState::BackPorch:
            if (v_count == 33) {
                v_state = ScanlineState::Visible;
                v_count = 0;
            }
            break;
    }

    if (h_state == ScanlineState::Visible && v_state == ScanlineState::Visible) {
        int i = 3 * (h_count + v_count * ScreenWidth);
        pixels[i++] = red * 0xFF;
        pixels[i++] = green * 0xFF;
        pixels[i]   = blue * 0xFF;
        dirty = true;
    } else if (dirty && v_state != ScanlineState::Visible) {
        SDL_Event event = { .type = event_type };
        SDL_PushEvent(&event);
        dirty = false;
    }
}
