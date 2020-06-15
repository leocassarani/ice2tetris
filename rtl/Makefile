TOP := computer
SRC := $(wildcard *.v)

PIN_DEF := icebreaker.pcf
DEVICE := up5k
PACKAGE := sg48

.PHONY: all
all: $(TOP).bin $(TOP).rpt

%.bin: %.asc
	icepack -s $< $@

%.rpt: %.asc
	icetime -d $(DEVICE) -mtr $@ $<

%.asc: $(PIN_DEF) %.json
	nextpnr-ice40 --$(DEVICE) --package $(PACKAGE) --json $(filter-out $<,$^) --pcf $< --asc $@

%.json: %.v $(SRC)
	yosys -ql $*.log -p 'synth_ice40 -top $(TOP) -json $@' $^

.PHONY: prog
prog: $(TOP).bin
	iceprog $<

.PHONY: flash
flash:
	$(if $(ROM),,$(error ROM is undefined))
	iceprog -o 1024k $(ROM)

.PHONY: clean
clean:
	rm -f $(TOP).asc $(TOP).bin $(TOP).json $(TOP).log $(TOP).rpt

.SECONDARY:
