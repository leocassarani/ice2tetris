#include <iostream>
#include <thread>
#include "Vcomputer.h"
#include "verilated.h"
#include "verilated_vcd_c.h"
#include "vga.h"

bool reset = true;

void tick(unsigned tickcount, Vcomputer *tb, VerilatedVcdC *tfp) {
    tb->eval();

    if (tfp)
        tfp->dump(tickcount * 10 - 2);

    tb->CLK = 1;
    tb->eval();

    if (tfp)
        tfp->dump(tickcount * 10);

    tb->CLK = 0;
    tb->eval();

    if (tfp) {
        tfp->dump(tickcount * 10 + 5);
        tfp->flush();
    }

    if (reset && !tb->LEDG_N) {
        reset = false;
        printf("ROM ready\n");
    }
}

void loop(Vcomputer *tb, VerilatedVcdC *tfp, VGA *vga) {
    unsigned tickcount = 0;

    for (int i = 0; i < 1000000; i++) {
        tick(++tickcount, tb, tfp);
        vga->Tick(tb->P1B7, tb->P1B8, tb->P1A4, tb->P1B4, tb->P1A10);
    }
    printf("Done\n");
}

int main(int argc, char **argv) {
    Verilated::commandArgs(argc, argv);

    Vcomputer *tb = new Vcomputer;
    tb->BTN_N = 1; // Reset button not pressed

    Verilated::traceEverOn(true);
    VerilatedVcdC *tfp = new VerilatedVcdC;

    VGA *vga = new VGA();

    tb->trace(tfp, 99);
    tfp->open("computer.vcd");

    std::thread th(&loop, tb, tfp, vga);
    th.detach();

    vga->Start();
    delete vga;

    return 0;
}
