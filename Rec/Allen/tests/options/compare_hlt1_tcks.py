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
"""For all configurations persisted by the create_hlt1_tcks
test/options file, load them from two repositories and from the JSON
files generated at build time. The entries in the two git repositories
were created from the JSON files generated at build time and directly
from their respective python modules.

If all configurations are identical then neither the persistence nor
the generation of configurations alters the content of the
configuration.
"""

import os
import sys
import json
from Allen.qmtest.utils import print_sequence_differences
from Allen.tck import manifest_from_git, sequence_from_git
from pathlib import Path

seq_dir = Path(os.path.expandvars("${ALLEN_INSTALL_DIR}/constants"))
json_repo = Path(os.getenv("PREREQUISITE_0", "")) / "config_json.git"
python_repo = Path(os.getenv("PREREQUISITE_0", "")) / "config_python.git"

manifest_json = manifest_from_git(json_repo)
manifest_python = manifest_from_git(python_repo)

# Digests are not necessarily the same, but manifest values should be
entries_json = sorted(manifest_json.values(), key=lambda v: v["TCK"])
entries_python = sorted(manifest_python.values(), key=lambda v: v["TCK"])

error = entries_json != entries_python
if error:
    print("ERROR: Manifests are not the same")

for m, suf in ((manifest_json, "json"), (manifest_python, "python")):
    with open(f"manifest_{suf}.json", "w") as f:
        json.dump(m, f)

for info in entries_json:
    sequence_json = json.loads(sequence_from_git(json_repo, info["TCK"])[0])
    sequence_python = json.loads(sequence_from_git(json_repo, info["TCK"])[0])
    sequence_type = next(v for v in info["Release2Type"].values())
    sequence_direct = None
    tck = info["TCK"]

    with open(str((seq_dir / f"{sequence_type}.json").resolve())) as js:
        sequence_direct = json.load(js)
        # Fixup the TCK here for comparison purposes because it's not
        # set when running from the JSON file
        sequence_direct['dec_reporter']['tck'] = int(tck, 16)

    if sequence_json != sequence_python:
        print(
            f"ERROR: sequences loaded from JSON and python git repos for TCK {tck} are not the same"
        )
        error = True
    if sequence_json != sequence_direct:
        print(
            f"ERROR: sequences loaded directly from JSON and from JSON git repo for {tck} are not the same"
        )

        print_sequence_differences(sequence_direct, sequence_json)
        error = True

sys.exit(error)
