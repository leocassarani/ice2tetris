#ifndef SIMULATOR_H
#define SIMULATOR_H

#include <atomic>
#include <memory>
#include <SDL2/SDL.h>
#include "Vcomputer.h"
#include "testbench.h"
#include "flash.h"
#include "keyboard.h"
#include "vga.h"

class Simulator {
public:
    Simulator(TestBench<Vcomputer>& tb);
    ~Simulator();

    void run();

private:
    TestBench<Vcomputer>& tb;

    Flash flash;
    Keyboard keyboard;
    VGA vga;

    std::atomic<bool> exit = false;
    std::atomic<bool> reset = false;

    std::unique_ptr<SDL_Window, void(*)(SDL_Window *)> window{nullptr, nullptr};
    std::unique_ptr<SDL_Renderer, void(*)(SDL_Renderer *)> renderer{nullptr, nullptr};
    std::unique_ptr<SDL_Texture, void(*)(SDL_Texture *)> texture{nullptr, nullptr};

    void simulate();
    void event_loop();

    void repaint();
    void key_press(const SDL_KeyboardEvent&);
};

#endif
