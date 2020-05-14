#include <stdio.h>
#include <stdlib.h>
#include "VComputer.h"
#include "verilated.h"
#include "verilated_vcd_c.h"

void tick(unsigned tickcount, VComputer *tb, VerilatedVcdC *tfp)
{
    tb->eval();

    if (tfp) {
        tfp->dump(tickcount * 10 - 2);
    }

    tb->CLK = 1;
    tb->eval();

    if (tfp) {
        tfp->dump(tickcount * 10);
    }

    tb->CLK = 0;
    tb->eval();

    if (tfp) {
        tfp->dump(tickcount * 10 + 5);
        tfp->flush();
    }
}

int main(int argc, char **argv)
{
    unsigned tickcount = 0;

    Verilated::commandArgs(argc, argv);
    VComputer *tb = new VComputer;

    Verilated::traceEverOn(true);
    VerilatedVcdC *tfp = new VerilatedVcdC;

    tb->trace(tfp, 99);
    tfp->open("computer.vcd");

    for (int i = 0; i < 10000; i++) {
        tick(++tickcount, tb, tfp);
    }
}
