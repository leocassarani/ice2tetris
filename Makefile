PROJ = computer
ADD_SRC = alu.v cpu.v clock.v memory.v rom.v screen.v

PIN_DEF = icebreaker.pcf
DEVICE = up5k

include main.mk
