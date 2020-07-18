.PHONY: all spike clean

all: spike/build/Makefile
	+make -C spike/build all
	+make -C sim all
	+make -C test all

spike/build/Makefile:
	mkdir -p spike/build
	cd spike/build; ../configure --enable-commitlog --enable-dirty --with-isa=RV32IM --with-priv=M CFLAGS= CXXFLAGS=

clean:
	-rm -r spike/build
	make -C sim clean
	make -C test clean
