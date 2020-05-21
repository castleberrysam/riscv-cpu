SRCS := $(wildcard *.s)
OUTS_ELF := $(SRCS:.s=.elf)
OUTS_HEX := $(SRCS:.s=.hex)

.PHONY: all clean

all: $(OUTS_ELF) $(OUTS_HEX)

%.o: %.s
	riscv64-linux-gnu-as -march=rv32i -o $@ $<

%.elf: %.o
	riscv64-linux-gnu-ld -melf32lriscv -Tlink.ld -o $@ $<

%.bin: %.elf
	riscv64-linux-gnu-objcopy -O binary $< $@

%.hex: %.bin
	xxd -e -c4 -g4 $< | cut -d' ' -f2 > $@

clean:
	-rm *.elf *.hex
