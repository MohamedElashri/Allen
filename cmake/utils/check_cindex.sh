#!/bin/bash
###############################################################################
# (c) Copyright 2021 CERN for the benefit of the LHCb Collaboration           #
#                                                                             #
# This software is distributed under the terms of the Apache License          #
# version 2 (Apache-2.0), copied verbatim in the file "LICENSE".              #
#                                                                             #
# In applying this licence, CERN does not waive the privileges and immunities #
# granted to it by virtue of its status as an Intergovernmental Organization  #
# or submit itself to any jurisdiction.                                       #
###############################################################################
if [ "$#" -eq 2 ]; then
    export PYTHONPATH="$1":${PYTHONPATH}
    export LD_LIBRARY_PATH="$2":${LD_LIBRARY_PATH}
fi
python3 -c "$(cat <<EOF
import sys
import inspect
try:
  import clang.cindex
  print(f'{inspect.getfile(clang.cindex)}', end='')
  sys.exit(0)
except ImportError:
  print('did not find cindex', end='')
  sys.exit(1)
EOF
)"
