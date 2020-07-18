#!/bin/sh

*.lst
if [ $# -lt 1 ]; then
    echo "Usage: $0 <test name>"
    exit 1
fi

make || exit $?
spike/build/spike -l --log-commits test/$1.elf 2>&1 | tee sim/spike.log
