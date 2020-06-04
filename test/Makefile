SRCS := $(wildcard *.s)
OUTS_ELF := $(SRCS:.s=.elf)
OUTS_HEX := $(SRCS:.s=.hex)

TEST_MAGIC := 0xdecafbad

.PHONY: all clean

all: $(OUTS_ELF) $(OUTS_HEX)

%.o: %.s
	riscv64-linux-gnu-as -march=rv32im --defsym TEST_MAGIC=$(TEST_MAGIC) -o $@ $<

%.elf: %.o link.ld
	riscv64-linux-gnu-ld -melf32lriscv -Tlink.ld -o $@ $<

%.bin: %.elf
	riscv64-linux-gnu-objcopy -O binary $< $@

%.xxd: %.bin
	xxd -e -c4 -g4 $< $@

%.hex: %.xxd
	cut -d' ' -f2 $< > $@

clean:
	-rm *.elf *.hex
