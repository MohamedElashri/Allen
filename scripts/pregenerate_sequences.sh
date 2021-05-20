#!/bin/bash
###############################################################################
# (c) Copyright 2018-2020 CERN for the benefit of the LHCb Collaboration      #
###############################################################################

SED="sed"
if [[ "$OSTYPE" == "darwin"* ]]; then
  SED="gsed"
fi

ALLEN_BASE_DIR="${PWD}/.."
PREGENERATED_DIR="${ALLEN_BASE_DIR}/configuration/pregenerated"

# Prepare tmp dir
TEMP_DIR=$(mktemp -d)
echo "Work dir: ${TEMP_DIR}"

mkdir "${TEMP_DIR}/code_generation"
CODE_GENERATION_SEQUENCES_DIR="${TEMP_DIR}/code_generation/sequences"
cp -r ${ALLEN_BASE_DIR}/configuration/sequences ${CODE_GENERATION_SEQUENCES_DIR}
cp -r ${ALLEN_BASE_DIR}/configuration/AllenCore ${CODE_GENERATION_SEQUENCES_DIR}

# Fetch PyConf
cd ${CODE_GENERATION_SEQUENCES_DIR}
git clone https://gitlab.cern.ch/lhcb/LHCb --no-checkout
git -C LHCb/ checkout HEAD -- PyConf
ln -s LHCb/PyConf/python/PyConf PyConf
git clone https://gitlab.cern.ch/gaudi/Gaudi --no-checkout
git -C Gaudi/ checkout HEAD -- GaudiKernel
ln -s Gaudi/GaudiKernel/python/GaudiKernel GaudiKernel

# Generate algorithms.py
cp -r ${ALLEN_BASE_DIR}/configuration/parser ${TEMP_DIR}/parser
cp -r ${ALLEN_BASE_DIR}/scripts/clang ${TEMP_DIR}/parser/clang
LD_LIBRARY_PATH=/cvmfs/sft.cern.ch/lcg/releases/clang/10.0.0-62e61/x86_64-centos7/lib:/cvmfs/sft.cern.ch/lcg/releases/gcc/9.2.0-afc57/x86_64-centos7/lib64:/Library/Developer/CommandLineTools/usr/lib:${LD_LIBRARY_PATH} CPLUS_INCLUDE_PATH=/cvmfs/sft.cern.ch/lcg/views/LCG_97python3/x86_64-centos7-gcc8-opt/include:${CPLUS_INCLUDE_PATH} python3 ${TEMP_DIR}/parser/ParseAlgorithms.py ${CODE_GENERATION_SEQUENCES_DIR}/AllenConf/algorithms.py ${ALLEN_BASE_DIR}/

# Generate sequences
cp ${ALLEN_BASE_DIR}/.clang-format .clang-format
for sequence in `ls | egrep ".py$" --color=none`; do
  SEQUENCE_NAME=`echo ${sequence} | sed -e "s/\(.*\)\.py/\1/g"`
  echo "Generating ${SEQUENCE_NAME}"
  python3 ${sequence}
  $SED -i "s:${ALLEN_BASE_DIR}:..:g" Sequence.h
  $SED -i "s:${ALLEN_BASE_DIR}:..:g" ConfiguredInputAggregates.h
  clang-format --style=file -i Sequence.h
  clang-format --style=file -i ConfiguredInputAggregates.h
  mv Sequence.h ${PREGENERATED_DIR}/${SEQUENCE_NAME}_sequence.h
  mv ConfiguredInputAggregates.h ${PREGENERATED_DIR}/${SEQUENCE_NAME}_input_aggregates.h
  mv Sequence.json ${PREGENERATED_DIR}/${SEQUENCE_NAME}.json
done

echo "Work dir: ${TEMP_DIR}"
echo "Generated all sequences"
