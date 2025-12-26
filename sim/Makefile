TOP := computer
VTOP := V$(TOP)

VDIR := ../rtl
VSRC := $(wildcard $(VDIR)/*.v)

VROOT := $(shell verilator -V | grep VERILATOR_ROOT | tail -1 | awk '{ print $$3 }')
VINC := $(VROOT)/include

CELLS_SIM := $(shell yosys-config --datdir/ice40/cells_sim.v)

# This can be overwritten at build time for smaller ROMs and faster loading times.
ROM_SIZE := 32768

BUILD_DIR := ./obj_dir

INPUT_DEVICE := $(if $(SNES),SNES_CONTROLLER,PS2_KEYBOARD)
CFLAGS := "-std=c++17 -D$(INPUT_DEVICE)"
LDFLAGS := -lSDL2
CXXSTD := -std=c++17

TARGET := computer_tb
CXXSRC := $(wildcard *.cpp)

.PHONY: build
build: $(BUILD_DIR)/$(VTOP).mk
	$(MAKE) -C $(BUILD_DIR) -f $(VTOP).mk

$(BUILD_DIR)/$(VTOP).mk: $(CXXSRC) $(VSRC)
	verilator \
		  -CFLAGS $(CFLAGS) \
		  -LDFLAGS $(LDFLAGS) \
		  -I$(VDIR) \
		  -o $(TARGET) \
		  --cc --exe --trace --MMD -O2 \
		  -Wall -Wno-lint \
		  +define+NO_ICE40_DEFAULT_ASSIGNMENTS \
		  +define+ROM_SIZE=$(ROM_SIZE) \
		  +define+$(INPUT_DEVICE) \
		  --top-module $(TOP) \
		  $(CELLS_SIM) $^

.PHONY: run
run: build
	$(BUILD_DIR)/$(TARGET) $(if $(ROM),+rom=$(ROM),)

.PHONY: trace
trace: build
	$(BUILD_DIR)/$(TARGET) $(if $(ROM),+rom=$(ROM),) +trace

.PHONY: clean
clean:
	rm -rf $(BUILD_DIR)
