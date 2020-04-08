from __future__ import print_function
import sys
import re

started = False

line_expr = re.compile(r"([A-Za-z0-9 ]+):\s+(\d+)/\s+(\d+)")

total = None

for line in sys.stdin:
    line = line.strip()
    if line.startswith("HLT1 rates"):
        started = True
        continue
    if started:
        m = line_expr.search(line)
        if not m:
            print("Couldn't match ", line)
        elif m.group(1) != "Inclusive":
            if total is None:
                total = int(m.group(3))
            else:
                assert (int(m.group(3)) == total)
            print("LAZY_AND: Hlt1%sLine #=%d Sum=%d" % (m.group(1), total,
                                                        int(m.group(2))))
        else:
            print("LAZY_AND: Hlt1PassThroughLine #=%d Sum=0" % total)
            print("LAZY_AND: moore #=%d Sum=%d" % (total, int(m.group(2))))
            started = False
