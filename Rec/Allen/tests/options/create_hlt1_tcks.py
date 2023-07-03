###############################################################################
# (c) Copyright 2023 CERN for the benefit of the LHCb Collaboration           #
#                                                                             #
# This software is distributed under the terms of the Apache License          #
# version 2 (Apache-2.0), copied verbatim in the file "COPYING".              #
#                                                                             #
# In applying this licence, CERN does not waive the privileges and immunities #
# granted to it by virtue of its status as an Intergovernmental Organization  #
# or submit itself to any jurisdiction.                                       #
###############################################################################
"""Create TCKs for a respresentative set of configurations. The
configurations should at least contain the dec_reporter algorithm for
this to make sense. Use both JSON files and the python modules they
were generated from and store the resulting configurations in
different git repositories with the same TCK.
"""

import os
import sys
import subprocess
from pathlib import Path
from Allen.qmtest.utils import good_sequence

seq_dir = os.path.expandvars("${ALLEN_INSTALL_DIR}/constants")
tck_script = os.path.expandvars("${ALLENROOT}/scripts/create_hlt1_tck.py")

error = False
sequences = [s for s in os.listdir(seq_dir) if good_sequence(s)]
# Create TCKs for few sequences in the DBG build to avoid timeouts
if '-dbg' in os.environ['BINARY_TAG']:
    import random
    random.seed("HLT1TCKs-dbg")
    random.shuffle(sequences)
    sequences = sequences[:5]


for i, seq in enumerate(sequences):
    seq = Path(seq_dir) / seq
    tck = hex(0x10000001 + i)

    # Create TCKs from python configurations
    # Note, these are created first such that missing encoding keys
    # will be added to the test-local metainfo repository
    r = subprocess.run([
        "python", tck_script, "RTA/2050.01.01", seq.stem, "config_python.git",
        tck
    ])
    if r.returncode != 0:
        error = True
    else:
        print(f"Created TCK {tck} from Python configuration {seq.stem}")
    os.rename(f"{tck}.json", f"{tck}_python.json")

    # Create TCKs from JSON files
    r = subprocess.run([
        "python", tck_script, "RTA/2050.01.01",
        str(seq), "config_json.git", tck
    ])
    if r.returncode != 0:
        error = True
    else:
        print(f"Created TCK {tck} from JSON configuration {str(seq)}")

if error:
    sys.exit(error)
