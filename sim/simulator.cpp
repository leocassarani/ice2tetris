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
    while (!exit) {
        tb.core.KEY = vga.key_pressed();
        tb.tick();
        vga.tick(tb.core.P1B7, tb.core.P1B8, tb.core.P1A4, tb.core.P1B4, tb.core.P1A10);
    }
}
