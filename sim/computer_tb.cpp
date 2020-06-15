#include <string>
#include "Vcomputer.h"
#include "simulator.h"
#include "testbench.h"

using std::string;

string rom_flag()
{
    auto flag = string(Verilated::commandArgsPlusMatch("rom"));
    auto len = flag.length();
    auto i = flag.find('=');

    // If there's no equal sign, or if the equal sign is the last character in
    // the string (no RHS), then default to a known filename.
    if (i == string::npos || i == len - 1)
        return "program.hack";

    return flag.substr(i + 1, flag.length());
}

bool trace_flag()
{
    auto trace = string(Verilated::commandArgsPlusMatch("trace"));
    return trace == "+trace";
}

int main(int argc, char **argv)
{
    Verilated::commandArgs(argc, argv);
    TestBench<Vcomputer> tb;

    auto rom = rom_flag();
    auto trace = trace_flag();

    if (trace)
        tb.open_trace("computer.vcd");

    Simulator sim(tb, rom);
    sim.run();

    return 0;
}
