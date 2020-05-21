python
import re

gdb.execute("set pagination off");

files = gdb.execute("info files", to_string=True);
testMatch = re.match("Symbols from \"([^\"]+)\"", files)
if not testMatch:
  print("Need to specify a test binary.")
  gdb.execute("quit")
test = testMatch.group(1)

gdb.execute("target remote | qemu-system-riscv32 -S -gdb stdio --cpu rv32 --display none --kernel " + test);
gdb.execute("si 5");

for i in range(32):
  gdb.execute("set $x" + str(i) + " = 0");

while True:
  insn = gdb.execute("x/i $pc", to_string=True)
  print(insn)
  if re.search("slti\s+zero,\s*zero,\s*0", insn):
    break
  gdb.execute("si")
  gdb.execute("info registers")

end
kill
quit
