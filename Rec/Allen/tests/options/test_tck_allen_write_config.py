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
"""Load all available configuration from a test repository, use them
to configure Allen and in turn dump Allen's configuration to a JSON
file. Then compare the configuration dumped by Allen to the original
TCK and check that they are identical.

This ensures that no properties are changed after they are set and a
round trip of load configuration, configure Allen, dump configuration
does not alter any properties as a side effect of configuration or
persistence.
"""

import os
import json
from pathlib import Path
from subprocess import PIPE, run
from Allen.qmtest.utils import print_sequence_differences
from Allen.tck import manifest_from_git, sequence_from_git

tck_repo = Path(os.getenv("PREREQUISITE_0", "")) / "config_json.git"

manifest = manifest_from_git(tck_repo)

# Take 5 configurations to check against Allen
manifest_entries = sorted(manifest.values(), key=lambda v: v["TCK"])

for info in manifest_entries:
    s, tck_info = sequence_from_git(tck_repo, info["TCK"])
    tck_sequence = json.loads(s)
    print('{release} {type:30s} {tck}'.format(**tck_info))
    tck = info["TCK"]

    cmd = [
        "Allen",
        "-g",  # Use default binary geometry, irrelavant in this mode, but needs to be found
        os.path.expandvars(
            "${ALLEN_PROJECT_ROOT}/input/detector_configuration"),
        "--param",
        os.path.expandvars("${PARAMFILESROOT}"),
        "--mdf",  # No input file
        '""',
        "--sequence",  # Load configuration from TCK
        f"config_json.git:{tck}",
        "--write-configuration",  # Write configuration to config.json
        "1",
    ]

    p = run(
        cmd,
        stdout=PIPE,
        stderr=PIPE,
    )
    if p.returncode != 0:
        print(f"Failed to write configuration from Allen for TCK {tck}")
        print(" ".join(cmd))
        print(p.stdout.decode())
        print(p.stderr.decode())
        error = True
    else:
        # Open configuration JSON written by Allen
        allen_sequence = ""
        with open("config.json") as f:
            allen_sequence = json.load(f)

        # Compare configurations
        if allen_sequence != tck_sequence:
            diffs = print_sequence_differences(tck_sequence, allen_sequence)
            print(
                "Differences between input configuration from TCK and written by Allen:"
            )
            print(diffs)
