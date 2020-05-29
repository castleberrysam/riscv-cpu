.PHONY: all clean

all:
	make -C sim all
	make -C test all

clean:
	make -C sim clean
	make -C test clean
