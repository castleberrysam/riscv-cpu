#!/bin/sh

if [ $# -lt 1 ]; then
    echo "Usage: $0 <test name>"
    exit 1
fi

make >/dev/null || exit $?
qemu-system-riscv32 -s -S --cpu rv32 --display none --kernel "test/$1.elf" &
QEMU_PID=$!
riscv64-linux-gnu-gdb -q --batch -ex 'source gdb-qemu.py' -ex run_test
kill -9 $QEMU_PID
