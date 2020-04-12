#!/bin/bash

SCRIPTS_DIR="${PWD}/../scripts"
SEQUENCE_DIR="${PWD}/../configuration/sequences"
PREGENERATED_DIR="${PWD}/../configuration/pregenerated"

LD_LIBRARY_PATH=/cvmfs/sft.cern.ch/lcg/releases/clang/10.0.0-62e61/x86_64-centos7/lib:/cvmfs/sft.cern.ch/lcg/releases/gcc/9.2.0-afc57/x86_64-centos7/lib:/cvmfs/sft.cern.ch/lcg/releases/gcc/9.2.0-afc57/x86_64-centos7/lib64:${LD_LIBRARY_PATH} python3 ${SCRIPTS_DIR}/ParseAlgorithms.py

mv algorithms.py ${SEQUENCE_DIR}/definitions/
cd ${SEQUENCE_DIR}

for sequence in `ls | egrep ".py$" --color=none`; do
  SEQUENCE_NAME=`echo ${sequence} | sed -e "s/\(.*\)\.py/\1/g"`

  echo "Generating ${SEQUENCE_NAME}"

  python3 ${sequence}
  mv Sequence.h ${PREGENERATED_DIR}/${SEQUENCE_NAME}.h
  mv Sequence.json ${PREGENERATED_DIR}/${SEQUENCE_NAME}.json
done

echo "Generated all sequences"
