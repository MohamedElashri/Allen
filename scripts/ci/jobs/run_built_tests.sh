#!/bin/bash -e
###############################################################################
# (c) Copyright 2018-2020 CERN for the benefit of the LHCb Collaboration      #
###############################################################################

set -euxo pipefail

check_build_exists

PREVIOUS_IFS=${IFS}
IFS=':' read -ra JOB_NAME_SPLIT <<< "${CI_JOB_NAME}"
IFS=':' read -ra CI_RUNNER_DESCRIPTION_SPLIT <<< "${CI_RUNNER_DESCRIPTION}"
IFS=${PREVIOUS_IFS}

setupViews

JUNITREPORT="$(realpath "${PWD}")/default-${BUILD_TYPE}-${SEQUENCE}-unit-tests.xml"

cd "${BUILD_FOLDER}" && ls
BUILD_DIR=`cat CTestTestfile.cmake | grep "# Build directory:" | awk '{ print $4 }'`
REPLACEMENT_DIR=${PWD}

sed -i CTestTestfile.cmake -e s:${BUILD_DIR}:${REPLACEMENT_DIR}:g
sed -i test/unit_tests/*.cmake -e s:${BUILD_DIR}:${REPLACEMENT_DIR}:g

if [ "${TARGET}" = "CPU" ]; then
    TOTAL_THREADS=$(lscpu | egrep "^CPU\(s\):.*[0-9]+$" --color=none | awk '{ print $2; }')
    TOTAL_NUMA_NODES=$(lscpu | egrep "^NUMA node\(s\):.*[0-9]+$" --color=none | awk '{ print $3; }')
    NUMA_NODE=${CI_RUNNER_DESCRIPTION_SPLIT[2]}
    THREADS=$((${TOTAL_THREADS} / ${TOTAL_NUMA_NODES}))

    # TODO: expand to support multiple catch2 executables
    LD_LIBRARY_PATH=$PWD:$LD_LIBRARY_PATH numactl --cpunodebind=${NUMA_NODE} --membind=${NUMA_NODE} \
        ./test/unit_tests/unit_tests -r junit | tee ${JUNITREPORT}
elif [ "${TARGET}" = "HIP" ]; then
    source_quietly /cvmfs/lhcbdev.cern.ch/tools/rocm-4.0.0/setenv.sh
    GPU_ID=${CI_RUNNER_DESCRIPTION_SPLIT[2]}
    GPU_NUMBER_EXTRA=`/opt/rocm-4.0.0/bin/rocm-smi --showuniqueid | grep $GPU_ID | awk '{ print $1; }'`
    GPU_ESCAPED_BRACKETS=`echo $GPU_NUMBER_EXTRA | sed 's/\[/\\\[/' | sed 's/\]/\\\]/'`
    PCI_BUS=`/opt/rocm-4.0.0/bin/rocm-smi --showbus | grep $GPU_ESCAPED_BRACKETS | awk '{ print $NF; }' | sed 's/[0-9]\+:\(.*\)/\1/'`
    GPU_NUMBER=`echo $GPU_NUMBER_EXTRA | sed 's/GPU\[\(.*\)\]/\1/g'`
    NUMA_NODE=`lspci -vmm | grep -i $PCI_BUS -A 10 | grep NUMANode | head -n1 | awk '{ print $NF; }'`

    LD_LIBRARY_PATH=$PWD:$LD_LIBRARY_PATH HIP_VISIBLE_DEVICES=${GPU_NUMBER} numactl --cpunodebind=${NUMA_NODE} \
        --membind=${NUMA_NODE} ./test/unit_tests/unit_tests -r junit | tee ${JUNITREPORT}
elif [ "${TARGET}" = "CUDA" ]; then
    GPU_UUID=${CI_RUNNER_DESCRIPTION_SPLIT[2]}
    GPU_NUMBER=`nvidia-smi -L | grep ${GPU_UUID} | awk '{ print $2; }' | sed -e 's/://'`
    NUMA_NODE=`nvidia-smi topo -m | grep GPU${GPU_NUMBER} | tail -1 | awk '{ print $NF; }'`
    export PATH=$PATH:/usr/local/cuda/bin

    LD_LIBRARY_PATH=$PWD:$LD_LIBRARY_PATH CUDA_DEVICE_ORDER=PCI_BUS_ID CUDA_VISIBLE_DEVICES=${GPU_NUMBER} \
        numactl --cpunodebind=${NUMA_NODE} --membind=${NUMA_NODE} ./test/unit_tests/unit_tests -r junit | tee ${JUNITREPORT}
else
    echo "TARGET ${TARGET} not supported. Please check your CI configuration."
    exit 1
fi
