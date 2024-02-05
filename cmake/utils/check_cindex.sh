#!/bin/bash
###############################################################################
# (c) Copyright 2021 CERN for the benefit of the LHCb Collaboration           #
###############################################################################
if [ "$#" -eq 2 ]; then
    export PYTHONPATH="$1":${PYTHONPATH}
    export LD_LIBRARY_PATH="$2":${LD_LIBRARY_PATH}
fi
python -c "$(cat <<EOF
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
