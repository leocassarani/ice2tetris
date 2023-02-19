SUBMAKE := $(MAKE) --no-print-directory -C

# Fully expand the path to the ROM variable so that the make tasks in the
# subdirectories only have to deal with absolute paths.
override ROM := $(abspath $(ROM))

.PHONY: rtl
rtl:
	+@$(SUBMAKE) rtl

.PHONY: prog
prog:
	+@$(SUBMAKE) rtl prog

.PHONY: flash
flash:
	+@$(SUBMAKE) rtl flash ROM=$(ROM)

.PHONY: sim
sim:
	+@$(SUBMAKE) sim

.PHONY: test
test:
	+@$(SUBMAKE) sim run ROM=$(ROM)

.PHONY: clean
clean:
	+@$(SUBMAKE) rtl clean
	+@$(SUBMAKE) sim clean
