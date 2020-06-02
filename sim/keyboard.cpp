#include "keyboard.h"

uint8_t Keyboard::current_key()
{
    switch (keycode) {
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

void Keyboard::key_down(SDL_Keysym &keysym)
{
    keycode = keysym.sym;
}

void Keyboard::key_up(SDL_Keysym &keysym)
{
    if (keycode == keysym.sym)
        keycode = 0;
}
