#!/bin/bash

TEST_DIR=$(mktemp -d)
cp -r ${1}/sequences ${TEST_DIR}
cp ${1}/tests/test_algorithms.py ${TEST_DIR}/sequences/definitions/algorithms.py
cp -r ${1}/AllenConf ${TEST_DIR}/sequences
cp -r ${1}/tests ${TEST_DIR}/sequences
cd ${TEST_DIR}/sequences
rm ${TEST_DIR}/sequences/tests/test_algorithms.py
pytest -s tests

echo ${TEST_DIR}
# rm -rf ${TEST_DIR}
