#!/bin/bash
###############################################################################
# (c) Copyright 2018-2020 CERN for the benefit of the LHCb Collaboration      #
###############################################################################

check_build_exists

# Configure RUN_OPTIONS.
set +x; set +u
# If already defined, let it stick.
if [ ! -z ${RUN_OPTIONS+x} ]; then
  RUN_OPTIONS=""
fi

# if a geometry folder is specified, pass it to Allen.
if [ ! -z ${GEOMETRY+x} ]; then
  RUN_OPTIONS="$RUN_OPTIONS -g /scratch/allen_geometries/${GEOMETRY}"
fi

RUN_OPTIONS="--mdf ${ALLEN_DATA}/mdf_input/${DATA_TAG}.mdf --sequence ${SEQUENCE}  --run-from-json 1 --params external/ParamFiles/ ${RUN_OPTIONS}"


if [ "${AVOID_HIP}" = "1" ]; then 
  if [ "${TARGET}" = "HIP" ]; then
    echo "***** Variable TARGET is set to HIP, and AVOID_HIP is set to 1 - quit."
    exit 0
  fi
fi

set -euxo pipefail
OUTPUT_FOLDER_REL="${TEST_NAME}_output_${SEQUENCE}_${DATA_TAG}${OPTIONS}/${DEVICE_ID}"
mkdir -p ${OUTPUT_FOLDER_REL}

OUTPUT_FOLDER=$(realpath ${OUTPUT_FOLDER_REL})
BUILD_FOLDER=$(realpath "${BUILD_FOLDER}")

if [ "${PROFILE_DEVICE}" = "${DEVICE_ID}" ]; then

  if [ "${TARGET}" != "CUDA" ]; then
    echo "PROFILE_DEVICE ${PROFILE_DEVICE} is not a CUDA device."
    echo "Profiling is only supported on CUDA devices. Please check the content of the PROFILE_DEVICE and TARGET variables."
    exit 1
  fi

  GPU_UUID=${CI_RUNNER_DESCRIPTION_SPLIT[2]}
  GPU_NUMBER=`nvidia-smi -L | grep ${GPU_UUID} | awk '{ print $2; }' | sed -e 's/://'`
  NUMA_NODE=`nvidia-smi topo -m | grep GPU${GPU_NUMBER} | tail -1 | awk '{ print $NF; }'`
  RUN_PROFILER_OPTIONS="${RUN_THROUGHPUT_OPTIONS_CUDAPROF} ${RUN_OPTIONS}"
  RUN_OPTIONS="${RUN_THROUGHPUT_OPTIONS_CUDA} ${RUN_OPTIONS}"
  export PATH=$PATH:/usr/local/cuda/bin

  setupViews

  cd ${BUILD_FOLDER} || exit 1
  ls
  export LD_LIBRARY_PATH=${PWD}:$LD_LIBRARY_PATH
  mkdir tmp

  CUDA_DEVICE_ORDER=PCI_BUS_ID CUDA_VISIBLE_DEVICES=${GPU_NUMBER} numactl --cpunodebind=${NUMA_NODE} --membind=${NUMA_NODE} ./toolchain/wrapper ./Allen ${RUN_OPTIONS} 2>&1 | tee ${OUTPUT_FOLDER}/output.txt

  # The following ncu command always fails at removing the tmp folder, ignore that failure with || true
  {
  CUDA_DEVICE_ORDER=PCI_BUS_ID CUDA_VISIBLE_DEVICES=${GPU_NUMBER} TMPDIR=tmp numactl --cpunodebind=${NUMA_NODE} --membind=${NUMA_NODE} ncu --print-summary per-kernel --target-processes all -o allen_report ./toolchain/wrapper ./Allen ${RUN_PROFILER_OPTIONS}
  } || true

  ncu -i allen_report.ncu-rep --csv > allen_report.csv
  python3 ${TOPLEVEL}/scripts/parse_ncu_output.py --input_filename=allen_report.csv --output_filename=allen_report_custom_metric.csv
  python3 ${TOPLEVEL}/checker/plotting/extract_algo_breakdown.py -f allen_report_custom_metric.csv -d ${OUTPUT_FOLDER}

  mv allen_report.csv ${OUTPUT_FOLDER}
  mv allen_report_custom_metric.csv ${OUTPUT_FOLDER}
  mv allen_report.ncu-rep ${OUTPUT_FOLDER}

  rm -rf tmp

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
    
    ALLEN="numactl --cpunodebind=${NUMA_NODE} --membind=${NUMA_NODE} ./toolchain/wrapper ./Allen ${RUN_OPTIONS}"

  elif [ "${TARGET}" = "CUDA" ]; then
    export PATH=$PATH:/usr/local/cuda/bin
    GPU_UUID=${CI_RUNNER_DESCRIPTION_SPLIT[2]}
    GPU_NUMBER=`nvidia-smi -L | grep ${GPU_UUID} | awk '{ print $2; }' | sed -e 's/://'`
    NUMA_NODE=`nvidia-smi topo -m | grep GPU${GPU_NUMBER} | tail -1 | awk '{ print $NF; }'`
    RUN_OPTIONS="${RUN_OPTIONS} ${RUN_THROUGHPUT_OPTIONS_CUDA}"
    
    ALLEN="CUDA_DEVICE_ORDER=PCI_BUS_ID CUDA_VISIBLE_DEVICES=${GPU_NUMBER} numactl --cpunodebind=${NUMA_NODE} --membind=${NUMA_NODE} ./toolchain/wrapper ./Allen ${RUN_OPTIONS}"

    nvidia-smi

  elif [ "${TARGET}" = "HIP" ]; then
    source_quietly /cvmfs/lhcbdev.cern.ch/tools/rocm-5.0.0/setenv.sh
    GPU_ID=${CI_RUNNER_DESCRIPTION_SPLIT[2]}
    GPU_NUMBER_EXTRA=`rocm-smi --showuniqueid | grep $GPU_ID | awk '{ print $1; }'`
    GPU_ESCAPED_BRACKETS=`echo $GPU_NUMBER_EXTRA | sed 's/\[/\\\[/' | sed 's/\]/\\\]/'`
    PCI_BUS=`rocm-smi --showbus | grep $GPU_ESCAPED_BRACKETS | awk '{ print $NF; }' | sed 's/[0-9]\+:\(.*\)/\1/'`
    GPU_NUMBER=`echo $GPU_NUMBER_EXTRA | sed 's/GPU\[\(.*\)\]/\1/g'`
    NUMA_NODE=`lspci -vmm | grep -i $PCI_BUS -A 10 | grep NUMANode | head -n1 | awk '{ print $NF; }'`
    RUN_OPTIONS="${RUN_OPTIONS} ${RUN_THROUGHPUT_OPTIONS_HIP}"

    ALLEN="HSA_NO_SCRATCH_RECLAIM=1 GPU_MAX_HW_QUEUES=8 HIP_VISIBLE_DEVICES=${GPU_NUMBER} numactl --cpunodebind=${NUMA_NODE} --membind=${NUMA_NODE} ./toolchain/wrapper ./Allen ${RUN_OPTIONS}"

    rocm-smi || echo "error occurred during rocm-smi; it will be ignored"

  fi
  echo "Command: ${ALLEN}"
  {
    eval "${ALLEN}"
  } 2>&1 | tee "${OUTPUT_FOLDER}/output.txt"
fi

###
# From here onwards, some bookkeeping for reporting throughput stats.

THROUGHPUT=$(cat ${OUTPUT_FOLDER}/output.txt | grep --color=none "events/s" | awk '{ print $1; }')
FULL_DEVICE_NAME=$(cat ${OUTPUT_FOLDER}/output.txt | grep --color=none "select device" | sed 's/.*:\ [0-9]*\,\ //')
THROUGHPUT_KHZ=$(python -c "print('%.2f' % (float(${THROUGHPUT}) / 1000.0))")
echo "Throughput (Hz): ${THROUGHPUT}"
echo "Throughput (kHz, 2 d.p.): ${THROUGHPUT_KHZ}"

echo "${DATA_TAG}" > "${OUTPUT_FOLDER}/input_files.txt"
echo "${SEQUENCE}" > "${OUTPUT_FOLDER}/sequence.txt"
echo "${OPTIONS}" > "${OUTPUT_FOLDER}/buildopts.txt"
echo "${THROUGHPUT}" > "${OUTPUT_FOLDER}/throughput.txt"
echo "${CI_COMMIT_SHORT_SHA}" > "${OUTPUT_FOLDER}/revision.txt"

# write metric to display on MR
echo "throughput_kHz{device=\"${DEVICE_ID}\",sequence=\"${SEQUENCE}\",dataset=\"${DATA_TAG}\"} ${THROUGHPUT_KHZ}" >> "${OUTPUT_FOLDER}/metrics.txt"


if [ "${TPUT_REPORT}" = "NO_REPORT" ]; then 
  echo "TPUT_REPORT is set to ${TPUT_REPORT} - throughput will not be reported."

  touch "${OUTPUT_FOLDER}/no_throughput_report.txt"
fi
