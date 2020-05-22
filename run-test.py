#!/usr/bin/env python3

import sys
import re
import glob
import os
from subprocess import Popen, PIPE, DEVNULL, TimeoutExpired

abi_names = {
    "zero": 0,
    "ra": 1,
    "sp": 2,
    "gp": 3,
    "tp": 4,
    "t0": 5,
    "t1": 6,
    "t2": 7,
    "fp": 8,
    "s1": 9,
    "a0": 10,
    "a1": 11,
    "a2": 12,
    "a3": 13,
    "a4": 14,
    "a5": 15,
    "a6": 16,
    "a7": 17,
    "s2": 18,
    "s3": 19,
    "s4": 20,
    "s5": 21,
    "s6": 22,
    "s7": 23,
    "s8": 24,
    "s9": 25,
    "s10": 26,
    "s11": 27,
    "t3": 28,
    "t4": 29,
    "t5": 30,
    "t6": 31
}

class Insn:
    def __init__(self, addr):
        self.addr = addr
        self.regvals = set()
    def add(self, regval):
        self.regvals.add(regval)
    def setaddr(self, addr):
        self.addr = addr
    def __str__(self):
        str_ = hex(self.addr) + " "
        for regval in self.regvals:
            str_ += "{" + regval[0] + "," + hex(regval[1]) + "}, "
        return str_
    def __eq__(self, other):
        return self.addr == other.addr and self.regvals == other.regvals

def run_iverilog(vvp_file, hex_file):
    process = Popen(["vvp", vvp_file, "+memfile=" + hex_file], stdout=PIPE)
    try:
        result = process.communicate(timeout=3)[0].decode()
    except TimeoutExpired:
        print("iverilog timed out")
        return None
    finally:
        process.kill()

    result = result.split("\n")

    insns = []
    insn = Insn(0)

    regs = [0] * 32
    for line in result:
        # check for reg write
        match = re.match("\s*\d+: regfile: port \d+ write (\S+) \S+ = (\S+)", line)
        if match:
            regname = match.group(1)
            regnum = abi_names[regname]
            regval = int(match.group(2), 16)
            if regval == regs[regnum]:
                continue
            regs[regnum] = regval
            insn.add((regname, regval))
            continue

        # check for retire msg
        match = re.match("\s*\d+: stage_(mem|write): retire insn at pc (\S+)", line)
        if match:
            insn.setaddr(int(match.group(2), 16))
            insns.append(insn)
            insn = Insn(0)
            continue
    return insns

def run_qemu(elf_file):
    process_qemu = Popen(["qemu-system-riscv32", "-s", "-S", "--cpu", "rv32",
                          "--display", "none", "--monitor", "stdio", "--kernel", elf_file],
                         stdin=PIPE, stdout=DEVNULL, stderr=DEVNULL);
    process_gdb = Popen(["riscv64-linux-gnu-gdb", "-q", "--batch",
                         "-ex", "source gdb-qemu.py",
                         "-ex", "run_test"],
                        stdout=PIPE, stderr=DEVNULL)
    try:
        result = process_gdb.communicate(timeout=3)[0].decode()
    except TimeoutExpired:
        print("gdb-qemu timed out")
        return None
    finally:
        process_gdb.kill()
        process_qemu.kill()

    result = result.split("\n")[3:-3]

    insns = []
    insn = None

    regs = [0] * 32
    pc = 0x80000000
    skip = 0
    for line in result:
        if skip > 0:
            skip -= 1
            continue
        parts = line.split()

        # check for new insn
        if parts[0] == "=>":
            if insn:
                insns.append(insn)
            addr_hex = parts[1]
            if addr_hex[-1] == ":":
                addr_hex = addr_hex[:-1]
            insn = Insn(int(addr_hex, 16))
            skip = 2
            continue
        # else, new value for reg
        parts = line.split()
        regname = parts[0]
        regval = int(parts[1], 16)
        if regname == "pc":
            if regval == pc:
                continue
            pc = regval
            #insn.add((regname, regval))
            continue
        regnum = abi_names[regname]
        if regval == regs[regnum]:
            continue
        regs[regnum] = regval
        insn.add((regname, regval))
    if insn:
        insns.append(insn)
    return insns

def main():
    if len(sys.argv) < 2:
        print("Usage: " + sys.argv[0] + " <test name>")
        return

    tests = []
    verbose = False
    if sys.argv[1] == "all":
        for elf in glob.iglob("test/*.elf"):
            tests.append(os.path.basename(elf)[:-4])
    else:
        verbose = True
        tests.append(sys.argv[1])

    if len(tests) == 0:
        print("No tests to run. Maybe you need to run make first.")
        return

    for test in tests:
        print("{:16s}".format(test + ":"), end="", flush=True)

        qemu_insns = run_qemu("test/" + test + ".elf")
        if not qemu_insns:
            continue

        iverilog_insns = run_iverilog("src/top", "test/" + test + ".hex")
        if not iverilog_insns:
            continue

        print("pass" if qemu_insns == iverilog_insns else "fail")

        if verbose:
            print("from qemu:")
            for insn in qemu_insns:
                print(insn)
            print("from iverilog:")
            for insn in iverilog_insns:
                print(insn)

if __name__ == "__main__":
    main()
