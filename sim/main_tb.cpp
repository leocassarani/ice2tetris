#include <string>
#include "Vcomputer.h"
#include "simulator.h"
#include "testbench.h"

using std::string;

int main(int argc, char **argv)
{
    Verilated::commandArgs(argc, argv);

    TestBench<Vcomputer> tb;
    tb.core.BTN_N = 1;

    string flag(Verilated::commandArgsPlusMatch("trace"));
    bool trace_enabled = flag == "+trace";

    if (trace_enabled)
        tb.open_trace("computer.vcd");

    Simulator sim(tb);
    sim.run();

    return 0;
}
