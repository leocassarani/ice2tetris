#include "simulator.h"

void Simulator::start()
{
    thread = std::thread(&Simulator::loop, this);
}

void Simulator::stop()
{
    exit = true;
    thread.join();
}

void Simulator::loop()
{
    uint8_t red, green, blue;

    while (!exit) {
        tb.core.KEY = vga.key_pressed();
        tb.tick();

        red = tb.core.P1A4 << 3 | tb.core.P1A3 << 2 | tb.core.P1A2 << 1 | tb.core.P1A1;
        green = tb.core.P1B4 << 3 | tb.core.P1B3 << 2 | tb.core.P1B2 << 1 | tb.core.P1B1;
        blue = tb.core.P1A10 << 3 | tb.core.P1A9 << 2 | tb.core.P1A8 << 1 | tb.core.P1A7;

        vga.tick(tb.core.P1B7, tb.core.P1B8, red, green, blue);
    }
}
