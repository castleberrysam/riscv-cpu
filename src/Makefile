SRCS := ../test/tb_top.v $(wildcard *.v)
HDRS := $(wildcard *.vh)

.PHONY: all clean

all: top

top: $(SRCS) $(HDRS)
	iverilog -Wall -o $@ $(SRCS)

clean:
	-rm top
