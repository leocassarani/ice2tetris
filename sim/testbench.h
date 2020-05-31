#ifndef TESTBENCH_H
#define TESTBENCH_H

#include <memory>
#include <string>
#include <verilated.h>
#include <verilated_vcd_c.h>

using std::string;

template <class VCore> class TestBench {
public:
    VCore core;

    TestBench()
    {
        core.CLK = 0;
        core.eval();
    }

    virtual ~TestBench()
    {
        close_trace();
    }

    virtual void open_trace(string filename) {
        Verilated::traceEverOn(true);

        trace = std::make_unique<VerilatedVcdC>();
        core.trace(trace.get(), 99);
        trace->open(filename.c_str());
    }

    virtual void close_trace() {
        if (trace)
            trace->close();
    }

    virtual void tick()
    {
        tickcount++;
        vluint64_t time = tickcount * 10;

        core.eval();

        if (trace)
            trace->dump(time - 2);

        core.CLK = 1;
        core.eval();

        if (trace)
            trace->dump(time);

        core.CLK = 0;
        core.eval();

        if (trace) {
            trace->dump(time + 5);
            trace->flush();
        }
    }

private:
    std::unique_ptr<VerilatedVcdC> trace;
    uint64_t tickcount = 0;
};

#endif
