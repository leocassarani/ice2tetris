PROJ = computer
ADD_SRC = alu.v clock.v cpu.v keyboard.v memory.v ram.v rom.v screen.v

PIN_DEF = icebreaker.pcf
DEVICE = up5k

include main.mk
