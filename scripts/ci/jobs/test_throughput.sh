#!/usr/bin/bash
###############################################################################
# (c) Copyright 2018-2020 CERN for the benefit of the LHCb Collaboration      #
###############################################################################

set -euo pipefail

setupViews

echo "All outputs:"
ls -1 | grep output_
echo ""

echo "run_throughput outputs:"
ls -1 | grep output | grep run_throughput

THROUGHPUT_ALARM=0
THROUGHPUT_MESSAGES=""
for SEQUENCE_DATASET in $(ls -1 | grep "run_throughput" | grep -Ei "run_throughput_output_([a-z0-9_]+?)" | sed 's/^run_throughput_output_//') ; do

    INPUT_FILES=$(cat run_throughput_output_${SEQUENCE_DATASET}/${BREAKDOWN_DEVICE_ID}/input_files.txt)
    SEQUENCE=$(cat run_throughput_output_${SEQUENCE_DATASET}/${BREAKDOWN_DEVICE_ID}/sequence.txt)
    BUILDOPTIONS=$(cat run_throughput_output_${SEQUENCE_DATASET}/${BREAKDOWN_DEVICE_ID}/buildopts.txt)

    # Somewhat strange way to pass on details to the publish job, but, we are working in bash...!
    mkdir -p test_throughput_details
    echo "${INPUT_FILES}" > test_throughput_details/${SEQUENCE_DATASET}_${BREAKDOWN_DEVICE_ID}_input_files.txt
    echo "${SEQUENCE}" > test_throughput_details/${SEQUENCE_DATASET}_${BREAKDOWN_DEVICE_ID}_sequence.txt
    echo "${BUILDOPTIONS}" > test_throughput_details/${SEQUENCE_DATASET}_${BREAKDOWN_DEVICE_ID}_buildopts.txt

    echo ""
    echo "********************************************************************************************************************************************"
    echo "********************************************************************************************************************************************"
    echo "Throughput of [branch ${CI_COMMIT_REF_NAME} (${CI_COMMIT_SHORT_SHA}), sequence ${SEQUENCE} over dataset ${INPUT_FILES}"
    echo ""
    echo ""
    cat run_throughput_output_${SEQUENCE_DATASET}/*/output.txt | grep --color=none "select device" | sed 's/.*:\ [0-9]*\,\ //' > devices_${SEQUENCE_DATASET}.txt
    cat run_throughput_output_${SEQUENCE_DATASET}/*/output.txt | grep --color=none "events/s" | awk '{ print $1; }' > throughputs_${SEQUENCE_DATASET}.txt
    paste -d, devices_${SEQUENCE_DATASET}.txt throughputs_${SEQUENCE_DATASET}.txt > devices_throughputs_${SEQUENCE_DATASET}.csv

    if [ "${BUILDOPTIONS}" = "" ]; then
        BUILDOPTIONS_DISPLAY="default"
    else
        BUILDOPTIONS_DISPLAY=${BUILDOPTIONS}
    fi

    RC=0
    python checker/plotting/check_throughput.py \
        -j "${CI_JOB_NAME}" \
        -t devices_throughputs_${SEQUENCE_DATASET}.csv || RC=$?

    if [ "$RC" = "7" ]; then
        THROUGHPUT_ALARM=1
        THROUGHPUT_MESSAGES="${THROUGHPUT_MESSAGES}
FAIL: throughput decreased too much for sequence ${SEQUENCE} over dataset ${INPUT_FILES}"
    elif [ "$RC" != "0" ]; then
        echo "FAIL: check_throughput.py script failed"
        exit 1
    fi

    echo ""
    echo ""
done

if [ "${THROUGHPUT_ALARM}" = "1" ]; then
    python checker/plotting/update_gitlab.py --throughput-status "decrease"
else
    python checker/plotting/update_gitlab.py --throughput-status "no-change"
fi

echo ""
echo ""
echo ${THROUGHPUT_MESSAGES}

exit $THROUGHPUT_ALARM
