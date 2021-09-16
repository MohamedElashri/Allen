#!/usr/bin/bash
###############################################################################
# (c) Copyright 2018-2020 CERN for the benefit of the LHCb Collaboration      #
###############################################################################

set -euxo pipefail

setupViews

echo "All outputs:"
ls -1 | grep output_
echo ""

echo "run_throughput outputs:"
ls -1 | grep output | grep run_throughput

for SEQUENCE_DATASET in $(ls -1 | grep "run_throughput" | grep -Ei "run_throughput_output_([a-z0-9_]+?)" | sed 's/^run_throughput_output_//') ; do
    INPUT_FILES=$(cat run_throughput_output_${SEQUENCE_DATASET}/${BREAKDOWN_DEVICE_ID}/input_files.txt)
    SEQUENCE=$(cat run_throughput_output_${SEQUENCE_DATASET}/${BREAKDOWN_DEVICE_ID}/sequence.txt)

    cat run_throughput_output_${SEQUENCE_DATASET}/*/output.txt | grep --color=none "select device" | sed 's/.*:\ [0-9]*\,\ //' > devices_${SEQUENCE_DATASET}.txt
    cat run_throughput_output_${SEQUENCE_DATASET}/*/output.txt | grep --color=none "events/s" | awk '{ print $1; }' > throughputs_${SEQUENCE_DATASET}.txt
    cat devices_${SEQUENCE_DATASET}.txt
    cat throughputs_${SEQUENCE_DATASET}.txt
    paste -d, devices_${SEQUENCE_DATASET}.txt throughputs_${SEQUENCE_DATASET}.txt > devices_throughputs_${SEQUENCE_DATASET}.csv
    cat devices_throughputs_${SEQUENCE_DATASET}.csv

    python checker/plotting/post_combined_message.py \
        -j "${CI_JOB_NAME}" \
        -l "Throughput of [branch **\`${CI_COMMIT_REF_NAME} (${CI_COMMIT_SHORT_SHA})\`**, sequence **\`${SEQUENCE}\`** over dataset **\`${INPUT_FILES}\`**](https://gitlab.cern.ch/lhcb/Allen/pipelines/${CI_PIPELINE_ID})" \
        -t devices_throughputs_${SEQUENCE_DATASET}.csv \
        -b run_throughput_output_${SEQUENCE_DATASET}/${BREAKDOWN_DEVICE_ID}/algo_breakdown.csv
    
    python checker/plotting/post_telegraf.py -f devices_throughputs_${SEQUENCE_DATASET}.csv . -s "${SEQUENCE}" -b "${CI_COMMIT_REF_NAME}" -d "${INPUT_FILES}"
done
