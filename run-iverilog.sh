#!/bin/sh

if [ $# -lt 1 ]; then
    echo "Usage: $0 <test name>"
    exit 1
fi

make >/dev/null || exit $?
vvp src/top +memfile="test/$1.hex"
