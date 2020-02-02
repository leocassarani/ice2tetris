all: $(PROJ).rpt $(PROJ).bin

%.blif: %.v $(ADD_SRC) $(ADD_DEPS)
	yosys -ql $*.log -p 'synth_ice40 -top $(PROJ) -blif $@' $< $(ADD_SRC)

%.json: %.v $(ADD_SRC) $(ADD_DEPS)
	yosys -ql $*.log -p 'synth_ice40 -top $(PROJ) -json $@' $< $(ADD_SRC)

%.asc: $(PIN_DEF) %.json
	nextpnr-ice40 --$(DEVICE) --package sg48 --json $(filter-out $<,$^) --pcf $< --asc $@

%.bin: %.asc
	icepack -s $< $@

%.rpt: %.asc
	icetime -d $(DEVICE) -mtr $@ $<

%_tb: %_tb.v %.v
	iverilog -o $@ $^

%_tb.vcd: %_tb
	vvp -N $< +vcd=$@

%_syn.v: %.blif
	yosys -p 'read_blif -wideports $^; write_verilog $@'

%_syntb: %_tb.v %_syn.v
	iverilog -o $@ $^ `yosys-config --datdir/ice40/cells_sim.v`

%_syntb.vcd: %_syntb
	vvp -N $< +vcd=$@

prog: $(PROJ).bin
	iceprog $<

clean:
	rm -f $(PROJ).blif $(PROJ).asc $(PROJ).rpt $(PROJ).bin $(PROJ).json $(PROJ).log $(ADD_CLEAN)

.SECONDARY:
.PHONY: all prog clean
