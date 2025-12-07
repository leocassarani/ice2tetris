TOP := computer
VTOP := V$(TOP)

VDIR := ../rtl
VSRC := $(wildcard $(VDIR)/*.v)

VROOT := $(shell verilator -V | grep VERILATOR_ROOT | tail -1 | awk '{ print $$3 }')
VINC := $(VROOT)/include

CELLS_SIM := $(shell yosys-config --datdir/ice40/cells_sim.v)

# This can be overwritten at build time for smaller ROMs and faster loading times.
ROM_SIZE := 32768

OBJ_DIR := ./obj_dir
BUILD_DIR := ./build

INCFLAGS := -I $(VINC) -I $(OBJ_DIR)
LDFLAGS := -lSDL2 -lpthread
CXXSTD := -std=c++17
CXXFLAGS := $(CXXSTD) $(INCFLAGS) -O2 -Wall -MMD -MP

SRCS := $(wildcard *.cpp)
OBJS := $(SRCS:%.cpp=$(BUILD_DIR)/%.o) $(BUILD_DIR)/verilated.o $(BUILD_DIR)/verilated_vcd_c.o
DEPS := $(OBJS:.o=.d)

TARGET := computer_tb

$(BUILD_DIR)/$(TARGET): $(OBJS) $(OBJ_DIR)/$(VTOP)__ALL.a
	$(CXX) $^ -o $@ $(LDFLAGS)

$(BUILD_DIR)/%.o: %.cpp $(OBJ_DIR)/$(VTOP).h
	$(build-cpp)

$(BUILD_DIR)/%.o: $(VINC)/%.cpp
	$(build-cpp)

$(OBJ_DIR)/$(VTOP)__ALL.a: $(OBJ_DIR)/$(VTOP).mk
	$(MAKE) -C $(OBJ_DIR) -f $(VTOP).mk

$(OBJ_DIR)/$(VTOP).mk: $(OBJ_DIR)/$(VTOP).h

$(OBJ_DIR)/$(VTOP).h: $(VSRC)
	verilator -CFLAGS $(CXXSTD) -I$(VDIR) -cc -trace -Wno-lint +define+NO_ICE40_DEFAULT_ASSIGNMENTS +define+ROM_SIZE=$(ROM_SIZE) --top-module $(TOP) $(TOP).v $(CELLS_SIM)

define build-cpp
	@mkdir -p $(dir $@)
	$(CXX) $(CXXFLAGS) -c $< -o $@
endef

.PHONY: run
run: $(BUILD_DIR)/$(TARGET)
	$(BUILD_DIR)/$(TARGET) $(if $(ROM),+rom=$(ROM),)

.PHONY: trace
trace: $(BUILD_DIR)/$(TARGET)
	$(BUILD_DIR)/$(TARGET) $(if $(ROM),+rom=$(ROM),) +trace

.PHONY: clean
clean:
	rm -rf $(BUILD_DIR)
	rm -rf $(OBJ_DIR)

-include $(DEPS)
