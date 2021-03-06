#!/bin/sh

if [ $# -lt 1 ]; then
    echo "Usage: $0 <test name>"
    exit 1
fi

make || exit $?
sim/axsim.sh --testplusarg memfile="../test/$1.hex" 2>&1 | tee sim/xsim.log
