#!/usr/bin/bash
###############################################################################
# (c) Copyright 2018-2020 CERN for the benefit of the LHCb Collaboration      #
###############################################################################

if [ ${TARGET} = "HIP" ]; then
  exit 0
fi

check_build_exists


RUN_OPTIONS="-n 1000 -m 1000 --run-from-json 1"

# Configure the input files (--mdf) and geometry (-g)

if [ ! -z ${GEOMETRY+x} ]; then
  RUN_OPTIONS="${RUN_OPTIONS} -g ../input/detector_configuration/${GEOMETRY}"
fi

set -euxo pipefail

RUN_OPTIONS="${RUN_OPTIONS} --mdf ${ALLEN_DATA}/mdf_input/${DATA_TAG}.mdf --sequence ${SEQUENCE}"

OUTPUT_FOLDER="${TEST_NAME}_output_${SEQUENCE}"

mkdir ${OUTPUT_FOLDER} && ln -s ${OUTPUT_FOLDER} "output" # Needed by Root build

BUILD_FOLDER=$(realpath "${BUILD_FOLDER}")
OUTPUT_FOLDER=$(realpath "${OUTPUT_FOLDER}")

cd ${BUILD_FOLDER} && ls || exit 1
export LD_LIBRARY_PATH=${PWD}:$LD_LIBRARY_PATH

JOB="./Allen ${RUN_OPTIONS}"
if [ "${TARGET}" = "CPU" ]; then
  ALLEN="numactl --cpunodebind=${NUMA_NODE} --membind=${NUMA_NODE} ${JOB}"
elif [ "${TARGET}" = "CUDA" ]; then
  export PATH=$PATH:/usr/local/cuda/bin

  GPU_NUMBER=$(nvidia-smi -L | grep "${GPU_UUID}" | awk '{ print $2; }' | sed -e 's/://')
  NUMA_NODE=$(nvidia-smi topo -m | grep "GPU${GPU_NUMBER}" | tail -1 | awk '{ print $NF; }')
  ALLEN="CUDA_DEVICE_ORDER=PCI_BUS_ID CUDA_VISIBLE_DEVICES=${GPU_NUMBER} numactl --cpunodebind=${NUMA_NODE} --membind=${NUMA_NODE} ${JOB}"
else
  echo "TARGET ${TARGET} not supported. Check your CI configuration."
  exit 1
fi

setupViews

{
  eval "${ALLEN}"
} 2>&1 | tee "${OUTPUT_FOLDER}/${DATA_TAG}_${SEQUENCE}_${DEVICE_ID}.txt"
