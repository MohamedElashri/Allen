#!/usr/bin/bash
###############################################################################
# (c) Copyright 2018-2020 CERN for the benefit of the LHCb Collaboration      #
###############################################################################

set -euo pipefail

setupViews

for SEQUENCE_DATASET in $(ls -1 | grep "run_throughput" | grep -Ei "run_throughput_output_([a-z0-9_]+?)" | sed 's/^run_throughput_output_//') ; do
    INPUT_FILES=$(cat test_throughput_details/${SEQUENCE_DATASET}_${BREAKDOWN_DEVICE_ID}_input_files.txt)
    SEQUENCE=$(cat test_throughput_details/${SEQUENCE_DATASET}_${BREAKDOWN_DEVICE_ID}_sequence.txt)
    BUILDOPTIONS=$(cat test_throughput_details/${SEQUENCE_DATASET}_${BREAKDOWN_DEVICE_ID}_buildopts.txt)

    echo ""
    echo "********************************************************************************************************************************************"
    echo "********************************************************************************************************************************************"
    echo "Throughput of [branch ${CI_COMMIT_REF_NAME} (${CI_COMMIT_SHORT_SHA}), sequence ${SEQUENCE} over dataset ${INPUT_FILES}"
    echo ""
    echo ""

    if [ "${BUILDOPTIONS}" = "" ]; then
        BUILDOPTIONS_DISPLAY="default"
    else
        BUILDOPTIONS_DISPLAY=${BUILDOPTIONS}
    fi

    RC=0
    python checker/plotting/post_combined_message.py \
        -j "${CI_JOB_NAME}" \
        -l "Throughput of [branch **\`${CI_COMMIT_REF_NAME} (${CI_COMMIT_SHORT_SHA})\`**, sequence **\`${SEQUENCE}\`** over dataset **\`${INPUT_FILES}\`** build options \`${BUILDOPTIONS_DISPLAY}\`](https://gitlab.cern.ch/lhcb/Allen/pipelines/${CI_PIPELINE_ID})" \
        -t devices_throughputs_${SEQUENCE_DATASET}.csv \
        -b run_throughput_output_${SEQUENCE_DATASET}/${BREAKDOWN_DEVICE_ID}/algo_breakdown.csv \
        || RC=$?

    python checker/plotting/post_telegraf.py \
        -f devices_throughputs_${SEQUENCE_DATASET}.csv . \
        -s "${SEQUENCE}" -b "${CI_COMMIT_REF_NAME}" -d "${INPUT_FILES}" -o "${BUILDOPTIONS}" \
        || echo "WARNING: failed to post to telegraf"

    echo ""
    echo ""
done
