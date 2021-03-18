#!/bin/bash
###############################################################################
# (c) Copyright 2021 CERN for the benefit of the LHCb Collaboration           #
#                                                                             #
# This software is distributed under the terms of the Apache License          #
# version 2 (Apache-2.0), copied verbatim in the file "COPYING".              #
#                                                                             #
# In applying this licence, CERN does not waive the privileges and immunities #
# granted to it by virtue of its status as an Intergovernmental Organization  #
# or submit itself to any jurisdiction.                                       #
###############################################################################

# Prepare tests in a separate dir
TEST_DIR=$(mktemp -d)
cp -r ${1}/sequences ${TEST_DIR}
cp ${1}/tests/test_algorithms.py ${TEST_DIR}/sequences/definitions/algorithms.py
cp -r ${1}/AllenConf ${TEST_DIR}/sequences
cp -r ${1}/tests ${TEST_DIR}/sequences
cd ${TEST_DIR}/sequences
rm ${TEST_DIR}/sequences/tests/test_algorithms.py ${TEST_DIR}/sequences/tests/test_configuration.sh

# Run tests
pytest -s tests

# Cleanup and exit
exit_code=$?
rm -rf ${TEST_DIR}
exit $exit_code
