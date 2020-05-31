#ifndef SIMULATOR_H
#define SIMULATOR_H

#include <atomic>
#include <thread>
#include "Vcomputer.h"
#include "testbench.h"
#include "vga.h"

class Simulator {
public:
    Simulator(TestBench<Vcomputer>& tb, VGA& vga)
        : tb(tb), vga(vga) {}

    void start();
    void stop();

private:
    TestBench<Vcomputer>& tb;
    VGA& vga;

    std::atomic<bool> exit = false;
    std::thread thread;

    void loop();
};

#endif
