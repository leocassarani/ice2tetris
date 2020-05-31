CXX := g++
CFLAGS := -std=c++17
LDFLAGS := -lSDL2
VROOT := $(shell verilator -V | grep VERILATOR_ROOT | head -1 | awk '{ print $$3 }')
VINC := $(VROOT)/include

TOP := computer
VTOP := V$(TOP)
VSRC := $(wildcard ../*.v)
OBJDIR := obj_dir
CELLS_SIM := $(shell yosys-config --datdir/ice40/cells_sim.v)
ROM_SIZE := $(shell wc -l program.hack | awk '{ print $$1 }')

main_tb: main_tb.cpp simulator.cpp vga.cpp $(OBJDIR)/$(VTOP)__ALL.a
	$(CXX) $(CFLAGS) $(LDFLAGS) -I $(VINC) -I $(OBJDIR) $(VINC)/verilated.cpp $(VINC)/verilated_vcd_c.cpp $^ -o $@

$(OBJDIR)/Vcomputer__ALL.a: $(OBJDIR)/$(VTOP).h $(OBJDIR)/$(VTOP).mk
	make -C $(OBJDIR) -f $(VTOP).mk

$(OBJDIR)/Vcomputer.h: $(VSRC)
	verilator -CFLAGS $(CFLAGS) -I.. -trace -Wno-lint -cc +define+ROM_SIZE=$(ROM_SIZE) --top-module $(TOP) $(TOP).v $(CELLS_SIM)

$(OBJDIR)/Vcomputer.mk: $(OBJDIR)/$(VTOP).h

clean:
	rm -f main_tb
	rm -f *.vcd
	rm -rf $(OBJDIR)

.PHONY: clean
.DELETE_ON_ERROR:
