#!/bin/bash -e
###############################################################################
# (c) Copyright 2018-2020 CERN for the benefit of the LHCb Collaboration      #
###############################################################################

set -euxo pipefail

check_build_exists

RUN_OPTIONS="-n 1000 -m 1000 --params external/ParamFiles/"
JOB="./toolchain/wrapper ./Allen --mdf ${ALLEN_DATA}/mdf_input/${DATA_TAG}.mdf --sequence ${SEQUENCE} ${RUN_OPTIONS}"

for RUN_CHANGES in ON OFF; do
  echo "RUN_CHANGES: $RUN_CHANGES"
(
  if [ "$RUN_CHANGES" = "OFF" ]; then
    OUTPUT_DIR="run_no_run_changes_output_${SEQUENCE}"
    RUN_OPTIONS="${RUN_OPTIONS} --disable-run-changes 1"
  else
    OUTPUT_DIR="run_with_run_changes_output_${SEQUENCE}"
    RUN_OPTIONS="${RUN_OPTIONS} --disable-run-changes 0"
  fi

  mkdir "${OUTPUT_DIR}" && ln -s "${OUTPUT_DIR}" output # Needed by Root build
  OUTPUT_DIR=$(realpath "${OUTPUT_DIR}")

  cd ${BUILD_FOLDER} && ls

  setupViews

  export LD_LIBRARY_PATH=${PWD}:$LD_LIBRARY_PATH


  # Configure job for target device.
  if [ "${TARGET}" = "CPU" ]; then
    ALLEN="numactl --cpunodebind=${NUMA_NODE} --membind=${NUMA_NODE} ${JOB}"
  elif [ "${TARGET}" = "CUDA" ]; then
    GPU_NUMBER=$(nvidia-smi -L | grep "${GPU_UUID}" | awk '{ print $2; }' | sed -e 's/://')
    NUMA_NODE=$(nvidia-smi topo -m | grep "GPU${GPU_NUMBER}" | tail -1 | awk '{ print $NF; }')
    export PATH=$PATH:/usr/local/cuda/bin
    ALLEN="CUDA_DEVICE_ORDER=PCI_BUS_ID CUDA_VISIBLE_DEVICES=${GPU_NUMBER} numactl --cpunodebind=${NUMA_NODE} --membind=${NUMA_NODE} ${JOB}"
  else
    echo "TARGET ${TARGET} not supported yet. Check your CI configuration."
    exit 1
  fi

  {
    eval "${ALLEN}"
  } 2>&1 | tee "${OUTPUT_DIR}/minbias_${DEVICE_ID}.txt"
)
  echo "-------"
  echo "-------"
done
