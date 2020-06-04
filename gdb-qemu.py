# this should be run after qemu is already started
# qemu-system-riscv32 -s -S --cpu rv32 --display none --kernel <elf file>

import gdb

TEST_MAGIC = "decafbad"

class RunTest(gdb.Command):
  def __init__(self):
    super(RunTest, self).__init__("run_test", gdb.COMMAND_USER)
  def invoke(self, arg, from_tty):
    gdb.execute("set pagination off")
    gdb.execute("set architecture riscv:rv32")
    gdb.execute("target remote localhost:1234")
    gdb.execute("si 5")
    for i in range(32):
      gdb.execute("set $x" + str(i) + " = 0")
    while True:
      insn = gdb.execute("x/xw $pc", to_string=True)
      if TEST_MAGIC in insn:
        break
      gdb.execute("x/i $pc")
      print()
      gdb.execute("si")
      gdb.execute("info registers")

RunTest()
