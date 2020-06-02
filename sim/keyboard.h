#ifndef KEYBOARD_H
#define KEYBOARD_H

#include <SDL2/SDL.h>

class Keyboard {
public:
    uint8_t current_key();

    void key_down(SDL_Keysym &);
    void key_up(SDL_Keysym &);

private:
    SDL_Keycode keycode;
};

#endif
