###############################################################################
# (c) Copyright 2000-2018 CERN for the benefit of the LHCb Collaboration      #
###############################################################################
import sys
import os
base_dir = sys.argv[1]
dump_directories = sys.argv[2].split(',')
files = {}
for dd in dump_directories:
    dump_dir = os.path.join(base_dir, dd)
    files[dd] = sorted([
        os.path.join(dd, f) for f in os.listdir(dump_dir)
        if not f.endswith('.root')
    ])

sizes = [(f, os.stat(os.path.join(base_dir, f)).st_size)
         for v in files.itervalues() for f in v]
sizes = sorted(sizes, key=lambda e: e[0])

with open("ref", "w") as ref:
    for f, s in sizes:
        ref.write("%s %d\n" % (f, s))
