#!/bin/bash
###############################################################################
# (c) Copyright 2018-2020 CERN for the benefit of the LHCb Collaboration      #
###############################################################################

check_build_exists

# Configure RUN_OPTIONS.
# If already defined, let it stick.
if [ ! -z ${RUN_OPTIONS+x} ]; then
  RUN_OPTIONS=""
fi

# if a geometry folder is specified, pass it to Allen.
if [ ! -z ${GEOMETRY+x} ]; then
  RUN_OPTIONS="$RUN_OPTIONS -g ${ALLEN_DATA}/${GEOMETRY}"
fi

# if INPUT_FILES is set, use that instead of $DATA_TAG
# otherwise, keep normal behaviour.
if [ ! -z ${INPUT_FILES+x} ]; then
  RUN_OPTIONS="-f ${ALLEN_DATA}/${INPUT_FILES} ${RUN_OPTIONS}"
else
  INPUT_FILES="${DATA_TAG}"
  RUN_OPTIONS="-f ${ALLEN_DATA}/${DATA_TAG} ${RUN_OPTIONS}"
fi


set -euxo pipefail
OUTPUT_FOLDER="${TEST_NAME}_output_${SEQUENCE}_${INPUT_FILES}/${DEVICE_ID}"
mkdir -p ${OUTPUT_FOLDER}

OUTPUT_FOLDER=$(realpath ${OUTPUT_FOLDER})
BUILD_FOLDER=$(realpath "${BUILD_FOLDER}")

if [ "${PROFILE_DEVICE}" = "${DEVICE_ID}" ]; then

  if [ "${TARGET}" -ne "CUDA" ]; then
    echo "PROFILE_DEVICE ${PROFILE_DEVICE} is not a CUDA device."
    echo "Profiling is only supported on CUDA devices. Please check the content of the PROFILE_DEVICE and TARGET variables."
    exit 1
  fi

  GPU_UUID=${CI_RUNNER_DESCRIPTION_SPLIT[2]}
  GPU_NUMBER=`nvidia-smi -L | grep ${GPU_UUID} | awk '{ print $2; }' | sed -e 's/://'`
  NUMA_NODE=`nvidia-smi topo -m | grep GPU${GPU_NUMBER} | tail -1 | awk '{ print $NF; }'`
  RUN_PROFILER_OPTIONS="${RUN_THROUGHPUT_OPTIONS_CUDAPROF} -t 1 ${RUN_OPTIONS}"
  RUN_OPTIONS="${RUN_THROUGHPUT_OPTIONS_CUDA} -t 16 ${RUN_OPTIONS}"
  export PATH=$PATH:/usr/local/cuda/bin

  setupViews

  cd ${BUILD_FOLDER} || exit 1
  ls
  export LD_LIBRARY_PATH=${PWD}:$LD_LIBRARY_PATH
  mkdir tmp

  CUDA_DEVICE_ORDER=PCI_BUS_ID CUDA_VISIBLE_DEVICES=${GPU_NUMBER} numactl --cpunodebind=${NUMA_NODE} --membind=${NUMA_NODE} ./Allen ${RUN_OPTIONS} 2>&1 | tee ${OUTPUT_FOLDER}/output.txt
  CUDA_DEVICE_ORDER=PCI_BUS_ID CUDA_VISIBLE_DEVICES=${GPU_NUMBER} TMPDIR=tmp numactl --cpunodebind=${NUMA_NODE} --membind=${NUMA_NODE} nsys profile --trace=cuda ./Allen ${RUN_PROFILER_OPTIONS}
  nsys stats --report gpukernsum report1.qdrep -o allen_report
  python3 ${TOPLEVEL}/checker/plotting/extract_algo_breakdown.py -f allen_report_gpukernsum.csv -d ${OUTPUT_FOLDER}

  rm -rf report1.qdrep tmp

else

  setupViews

  cd ${BUILD_FOLDER} && ls
  export LD_LIBRARY_PATH=${PWD}:$LD_LIBRARY_PATH

  # Configure job for target device.
  if [ "${TARGET}" = "CPU" ]; then
    TOTAL_THREADS=$(lscpu | egrep "^CPU\(s\):.*[0-9]+$" --color=none | awk '{ print $2; }')
    TOTAL_NUMA_NODES=$(lscpu | egrep "^NUMA node\(s\):.*[0-9]+$" --color=none | awk '{ print $3; }')
    NUMA_NODE=${CI_RUNNER_DESCRIPTION_SPLIT[2]}
    THREADS=$((${TOTAL_THREADS} / ${TOTAL_NUMA_NODES}))
    RUN_OPTIONS="${RUN_OPTIONS} ${RUN_THROUGHPUT_OPTIONS_CPU} -t ${THREADS}"

    ALLEN="numactl --cpunodebind=${NUMA_NODE} --membind=${NUMA_NODE} ./Allen ${RUN_OPTIONS}"
  elif [ "${TARGET}" = "CUDA" ]; then
    export PATH=$PATH:/usr/local/cuda/bin
    GPU_UUID=${CI_RUNNER_DESCRIPTION_SPLIT[2]}
    GPU_NUMBER=`nvidia-smi -L | grep ${GPU_UUID} | awk '{ print $2; }' | sed -e 's/://'`
    NUMA_NODE=`nvidia-smi topo -m | grep GPU${GPU_NUMBER} | tail -1 | awk '{ print $NF; }'`
    RUN_OPTIONS="${RUN_OPTIONS} ${RUN_THROUGHPUT_OPTIONS_CUDA} -t 16"

    ALLEN="CUDA_DEVICE_ORDER=PCI_BUS_ID CUDA_VISIBLE_DEVICES=${GPU_NUMBER} numactl --cpunodebind=${NUMA_NODE} --membind=${NUMA_NODE} ./Allen ${RUN_OPTIONS}"

    nvidia-smi

  elif [ "${TARGET}" = "HIP" ]; then
    source_quietly /cvmfs/lhcbdev.cern.ch/tools/rocm-4.0.0/setenv.sh
    GPU_ID=${CI_RUNNER_DESCRIPTION_SPLIT[2]}
    GPU_NUMBER_EXTRA=`/opt/rocm-4.0.0/bin/rocm-smi --showuniqueid | grep $GPU_ID | awk '{ print $1; }'`
    GPU_ESCAPED_BRACKETS=`echo $GPU_NUMBER_EXTRA | sed 's/\[/\\\[/' | sed 's/\]/\\\]/'`
    PCI_BUS=`/opt/rocm-4.0.0/bin/rocm-smi --showbus | grep $GPU_ESCAPED_BRACKETS | awk '{ print $NF; }' | sed 's/[0-9]\+:\(.*\)/\1/'`
    GPU_NUMBER=`echo $GPU_NUMBER_EXTRA | sed 's/GPU\[\(.*\)\]/\1/g'`
    NUMA_NODE=`lspci -vmm | grep -i $PCI_BUS -A 10 | grep NUMANode | head -n1 | awk '{ print $NF; }'`
    RUN_OPTIONS="${RUN_OPTIONS} --events-per-slice 8000 ${RUN_THROUGHPUT_OPTIONS_HIP} -t 6"

    ALLEN="HIP_VISIBLE_DEVICES=${GPU_NUMBER} numactl --cpunodebind=${NUMA_NODE} --membind=${NUMA_NODE} ./Allen ${RUN_OPTIONS}"
  fi
  echo "Command: ${ALLEN}"
  { 
    eval "${ALLEN}" 
  } 2>&1 | tee "${OUTPUT_FOLDER}/output.txt"
fi

THROUGHPUT=$(cat ${OUTPUT_FOLDER}/output.txt | grep --color=none "events/s" | awk '{ print $1; }')
FULL_DEVICE_NAME=$(cat ${OUTPUT_FOLDER}/output.txt | grep --color=none "select device" | sed 's/.*:\ [0-9]*\,\ //')
THROUGHPUT_KHZ=$(python -c "import os; print('%.2f' % (float(${THROUGHPUT}) / 1000.0))")
echo "Throughput (Hz): ${THROUGHPUT}"
echo "Throughput (kHz, 2 d.p.): ${THROUGHPUT_KHZ}"

echo "${INPUT_FILES}" > "${OUTPUT_FOLDER}/input_files.txt"
echo "${SEQUENCE}" > "${OUTPUT_FOLDER}/sequence.txt"

# write metrics to display on MR
echo "HELP throughput_${DEVICE_ID} Throughput measurement for ${FULL_DEVICE_NAME} (${DEVICE_ID}) sequence ${SEQUENCE} over dataset ${INPUT_FILES}" > "${OUTPUT_FOLDER}/metrics.txt"
echo "TYPE throughput_${DEVICE_ID} summary" >> "${OUTPUT_FOLDER}/metrics.txt"
echo "throughput_${DEVICE_ID}{target=${TARGET}, sequence=${SEQUENCE}, dataset=${INPUT_FILES}, unit=kHz} ${THROUGHPUT_KHZ}" >> "${OUTPUT_FOLDER}/metrics.txt"
