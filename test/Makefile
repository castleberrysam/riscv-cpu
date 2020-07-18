TEST_MAGIC := 0xbaddecaf

TARGET := riscv64-unknown-elf
AS := $(TARGET)-as
CPP := $(TARGET)-cpp
CC := $(TARGET)-gcc
LD := $(TARGET)-ld
ASFLAGS := -march=rv32im -mabi=ilp32
CFLAGS := $(ASFLAGS) -O2 -nostartfiles
LDFLAGS := -Tlink.ld -Wl,--defsym,TEST_MAGIC=$(TEST_MAGIC)

SRCS_S := $(wildcard *.s)
SRCS_C := $(filter-out dhry_1.c dhry_2.c, $(wildcard *.c))
OUTS_ELF := $(SRCS_S:.s=.elf) $(SRCS_C:.c=.elf) dhry.elf
OUTS_HEX := $(OUTS_ELF:.elf=.hex)

.PHONY: all clean

all: $(OUTS_ELF) $(OUTS_HEX)

%.elf %.o: %.s link.ld
	$(AS) $(ASFLAGS) -o $*.o $<
	$(LD) -b elf32-littleriscv -Tlink.ld --defsym TEST_MAGIC=$(TEST_MAGIC) -o $*.elf $*.o

%.elf: %.o crt0.o link.ld
	$(CC) $(CFLAGS) $(LDFLAGS) -o $@ crt0.o $<

dhry.elf: dhry_1.o dhry_2.o crt0.o link.ld
	$(CC) $(CFLAGS) $(LDFLAGS) -o $@ crt0.o dhry_1.o dhry_2.o

%.bin: %.elf
	riscv64-unknown-elf-objcopy -O binary $< $@

%.xxd: %.bin
	xxd -e -c4 -g4 $< $@

%.hex: %.xxd
	cut -d' ' -f2 $< > $@

clean:
	-rm -r *.elf *.hex *.xxd *.o *.bin logs/
