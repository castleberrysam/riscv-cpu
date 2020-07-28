#!/usr/bin/env python3

import sys
import re
import glob
import os
import errno
import signal
from argparse import ArgumentParser
from subprocess import Popen, PIPE, STDOUT

TEST_MAGIC = 0xbaddecaf
TEST_TIMEOUT = 5 # seconds

def mkdir(path: str):
    try:
        os.mkdir(path)
    except OSError as e:
        if e.errno != errno.EEXIST:
            raise e

# returns -1 when encountering x or z
def hex2int(hexstr: str) -> int:
    if len(hexstr) >= 2 and hexstr[0] == "0" and hexstr[1].lower() == "x":
        return -1
    try:
        return int(hexstr, 16)
    except ValueError:
        return -1

class Log:
    def __init__(self, path: str, verbose: bool):
        self.path = path
        self.verbose = verbose
        self.fd = None
    def __enter__(self):
        if self.fd:
            self.fd.close()
        self.fd = open(self.path, "w")
        return self
    def __exit__(self, exc_type, exc_value, traceback):
        if self.fd:
            self.fd.close()
        self.fd = None
    def write(self, msg: str):
        if self.fd:
            self.fd.write(msg)
        if self.verbose:
            sys.stdout.write(msg)

class Process:
    def __init__(self, cmd: str, log: Log):
        self.cmd = cmd.split()
        self.handle = None
        self.log = log
    def __enter__(self):
        self.handle = Popen(self.cmd, stdout=PIPE, stderr=STDOUT, universal_newlines=True, start_new_session=True);
        return self
    def __exit__(self, exc_type, exc_value, traceback):
        os.killpg(os.getpgid(self.handle.pid), signal.SIGKILL)
        self.handle = None
    def readline(self) -> str:
        line = self.handle.stdout.readline()
        self.log.write(line)
        return line

class Instruction:
    def __init__(self):
        self.pc = None
        self.exc = False
        self.regs = {} # int -> int, maps register numbers to new values
    def __eq__(self, other):
        return other and self.pc == other.pc and self.exc == other.exc and self.regs == other.regs
    def __str__(self):
        ret = "pc={:08x}".format(self.pc)
        ret += " exc={}".format(self.exc)
        for reg in sorted(self.regs.keys()):
            ret += " x{}={:08x}".format(reg, self.regs[reg])
        return ret

class VerilogSim(Process):
    def __init__(self, testname: str, log: Log):
        plusargs = {}
        plusargs["memfile"] = "../test/{}.hex".format(testname)
        cmd = "sim/axsim.sh"
        for key,value in sorted(plusargs.items()):
            cmd += " --testplusarg {}={}".format(key, value)
        super().__init__(cmd, log)
    def step(self) -> Instruction:
        insn = Instruction()
        while True:
            line = self.readline()
            if line.startswith("$finish called"):
                return None
            match = re.match("\s*\d+: regfile: write \S+ (\S+) = (\S+)", line)
            if match:
                regnum = int(match.group(1)[2:-1])
                regval = hex2int(match.group(2))
                insn.regs[regnum] = regval
                continue
            match = re.match("\s*\d+: stage_write: retire insn at pc (\S+)", line)
            if match:
                insn.pc = hex2int(match.group(1))
                break
            match = re.match("\s*\d+: stage_write: take exception at pc (\S+)", line)
            if match:
                insn.pc = hex2int(match.group(1))
                insn.exc = True
                break
        return insn

class SpikeSim(Process):
    def __init__(self, testname: str, log: Log):
        super().__init__("spike/build/spike -l --log-commits test/{}.elf".format(testname), log)
    def step(self) -> Instruction:
        insn = Instruction()
        while True:
            line = self.readline()
            match = re.match("core\s*\d+:\s*(0x\S+)\s*(\S+)", line)
            if not match:
                continue
            insn.pc = int(match.group(1), 16)
            bytecode = int(match.group(2)[1:-1], 16) & 0xffffffff
            if bytecode == TEST_MAGIC:
                return None
            line = self.readline()
            match = re.match("core\s*\d+:\s*exception", line)
            if match:
                insn.exc = True
                break
            fields = iter(line[26:].split())
            for field in fields:
                if field[0] == "x":
                    regnum = int(field[1:])
                    regval = int(next(fields), 16)
                    insn.regs[regnum] = regval
                    continue
                if field == "store":
                    next(fields)
                next(fields)
            break
        return insn

class Test:
    def __init__(self, name: str, verbose: bool):
        self.name = name
        self.verbose = verbose
        self.success = None

    def run(self):
        log = Log("test/logs/{}.log".format(self.name), self.verbose)
        xsim = VerilogSim(self.name, log)
        spike = SpikeSim(self.name, log)
        with log, spike, xsim:
            while True:
                xsim_insn = xsim.step()
                spike_insn = spike.step()
                if xsim_insn != spike_insn:
                    log.write("TEST FAILED: instruction mismatch\n")
                    log.write("xsim: {}\n".format(xsim_insn))
                    log.write("spike: {}\n".format(spike_insn))
                    self.success = False
                    return
                if not xsim_insn:
                    log.write("TEST PASSED\n")
                    self.success = True
                    return

def main():
    parser = ArgumentParser()
    parser.add_argument("-v", action="store_true")
    parser.add_argument("--notimeout", action="store_true")
    parser.add_argument("testnames", action="append")
    args = parser.parse_args()

    if args.testnames == ["all"]:
        args.testnames = []
        for test in glob.iglob("test/*.elf"):
            args.testnames.append(os.path.basename(test)[:-4])
        if len(args.testnames) == 0:
            print("No test binaries found. Maybe you need to run make first.")
            return

    tests = []
    for testname in args.testnames:
        if not os.path.exists("test/{}.elf".format(testname)):
            print("Test binary test/{}.elf doesn't exist. Maybe you need to run make first.".format(testname))
            return
        tests.append(Test(testname, args.v))

    def alarm_handler(signum, frame):
        raise TimeoutError
    signal.signal(signal.SIGALRM, alarm_handler)

    mkdir("test/logs")

    for test in tests:
        if not args.v:
            print("{:16s}".format(test.name + ":"), end="", flush=True)

        try:
            if not args.notimeout:
                signal.alarm(TEST_TIMEOUT)
            test.run()
        except TimeoutError:
            print("timed out")
            continue

        if not args.v:
            print("pass" if test.success else "fail")

if __name__ == "__main__":
    main()
