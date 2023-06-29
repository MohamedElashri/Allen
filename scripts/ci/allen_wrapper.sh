###############################################################################
# (c) Copyright 2018-2022 CERN for the benefit of the LHCb Collaboration      #
###############################################################################

#!/bin/bash

source scripts/ci/common.sh

check_build_exists
setupViews

BUILD_FOLDER=$(realpath "${BUILD_FOLDER}")

# Not always set
set +u;
RUN_PROFILER_OUTPUT=$(realpath "${RUN_PROFILER_OUTPUT}/")
JUNITREPORT=$(realpath "${JUNITREPORT}/")
set -u;

cd ${BUILD_FOLDER} # && ls
export LD_LIBRARY_PATH="${LD_LIBRARY_PATH:+LD_LIBRARY_PATH:}${PWD}"

# Configure job for target device.
if [ "${TARGET}" = "CPU" ]; then
    TOTAL_THREADS=$(lscpu | egrep "^CPU\(s\):.*[0-9]+$" --color=none | awk '{ print $2; }')
    TOTAL_NUMA_NODES=$(lscpu | egrep "^NUMA node\(s\):.*[0-9]+$" --color=none | awk '{ print $3; }')
    NUMA_NODE=${CI_RUNNER_DESCRIPTION_SPLIT[2]}
    THREADS=$((${TOTAL_THREADS} / ${TOTAL_NUMA_NODES}))

    CMDPREFIX="numactl --cpunodebind=${NUMA_NODE} --membind=${NUMA_NODE} ./toolchain/wrapper"
    ALLEN="./Allen -t ${THREADS}"
elif [ "${TARGET}" = "CUDA" ]; then
    export PATH=$PATH:/usr/local/cuda/bin
    GPU_UUID=${CI_RUNNER_DESCRIPTION_SPLIT[2]}
    GPU_NUMBER=$(nvidia-smi -L | grep ${GPU_UUID} | awk '{ print $2; }' | sed -e 's/://')
    NUMA_NODE=$(nvidia-smi topo --id ${GPU_UUID} --get-numa-id-of-nearby-cpu | awk '{ print $NF; }')
    CMDPREFIX="CUDA_DEVICE_ORDER=PCI_BUS_ID CUDA_VISIBLE_DEVICES=${GPU_NUMBER} numactl --cpunodebind=${NUMA_NODE} --membind=${NUMA_NODE} ./toolchain/wrapper"

    ALLEN="./Allen"

    nvidia-smi
    nvidia-smi topo -m

elif [ "${TARGET}" = "HIP" ]; then
    source_quietly /cvmfs/lhcbdev.cern.ch/tools/rocm-5.0.0/setenv.sh
    GPU_ID=${CI_RUNNER_DESCRIPTION_SPLIT[2]}
    GPU_NUMBER_EXTRA=`rocm-smi --showuniqueid | grep $GPU_ID | awk '{ print $1; }'`
    GPU_ESCAPED_BRACKETS=`echo $GPU_NUMBER_EXTRA | sed 's/\[/\\\[/' | sed 's/\]/\\\]/'`
    PCI_BUS=`rocm-smi --showbus | grep $GPU_ESCAPED_BRACKETS | awk '{ print $NF; }' | sed 's/[0-9]\+:\(.*\)/\1/'`
    GPU_NUMBER=`echo $GPU_NUMBER_EXTRA | sed 's/GPU\[\(.*\)\]/\1/g'`
    NUMA_NODE=`lspci -vmm | grep -i $PCI_BUS -A 10 | grep NUMANode | head -n1 | awk '{ print $NF; }'`

    CMDPREFIX="HSA_NO_SCRATCH_RECLAIM=1 GPU_MAX_HW_QUEUES=8 HIP_VISIBLE_DEVICES=${GPU_NUMBER} numactl --cpunodebind=${NUMA_NODE} --membind=${NUMA_NODE} ./toolchain/wrapper"

    ALLEN="./Allen"

    rocm-smi || echo "error occurred during rocm-smi; it will be ignored"
fi


set +u; # Avoid RUN_PROFILER unbound error

if [ "${RUN_UNIT_TESTS}" = "1" ]; then 
    BUILD_DIR=`cat CTestTestfile.cmake | grep "# Build directory:" | awk '{ print $4 }'`
    REPLACEMENT_DIR=${PWD}
    sed -i CTestTestfile.cmake -e s:${BUILD_DIR}:${REPLACEMENT_DIR}:g
    sed -i test/unit_tests/*.cmake -e s:${BUILD_DIR}:${REPLACEMENT_DIR}:g
    # JUNITREPORT must be set externally.
    eval "${CMDPREFIX} ./test/unit_tests/unit_tests -r junit | tee ${JUNITREPORT}"
elif [ "${RUN_PROFILER}" = "1" ]; then
  set -u;
  if [ "${TARGET}" != "CUDA" ]; then
    echo "DEVICE_ID ${DEVICE_ID} is not a CUDA device."
    echo "Profiling is only supported on CUDA devices. Please check the content of the PROFILE_DEVICE and TARGET variables."
    exit 1
  fi

  mkdir tmp

  mkdir -p "${RUN_PROFILER_OUTPUT}"

  # The following ncu command always fails at removing the tmp folder, ignore that failure with || true
  {
  eval "CUDA_DEVICE_ORDER=PCI_BUS_ID CUDA_VISIBLE_DEVICES=${GPU_NUMBER} TMPDIR=tmp numactl --cpunodebind=${NUMA_NODE} --membind=${NUMA_NODE} ncu --print-summary per-kernel --target-processes all -o allen_report ./toolchain/wrapper ./Allen $@"
  } || true

  ncu -i allen_report.ncu-rep --csv > "${RUN_PROFILER_OUTPUT}/allen_report.csv"
  mv allen_report.ncu-rep ${RUN_PROFILER_OUTPUT}/allen_report.ncu-rep
  python3 ${TOPLEVEL}/scripts/parse_ncu_output.py --input_filename="${RUN_PROFILER_OUTPUT}/allen_report.csv" --output_filename="${RUN_PROFILER_OUTPUT}/allen_report_custom_metric.csv"
  python3 ${TOPLEVEL}/checker/plotting/extract_algo_breakdown.py -f "${RUN_PROFILER_OUTPUT}/allen_report_custom_metric.csv" -d "${RUN_PROFILER_OUTPUT}/"

  rm -rf tmp

  echo "Profiler output: ${RUN_PROFILER_OUTPUT}"
else
    eval "${CMDPREFIX} ${ALLEN} $@"
fi
