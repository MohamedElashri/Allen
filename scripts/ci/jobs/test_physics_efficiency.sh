#!/usr/bin/bash
###############################################################################
# (c) Copyright 2018-2020 CERN for the benefit of the LHCb Collaboration      #
###############################################################################

set -euxo pipefail

TOPLEVEL=$(realpath ${PWD})
ls "${TOPLEVEL}/test/reference"
mkdir -p ${TOPLEVEL}/generated_reference_files/
set +x;
RC=0
DIFFERENCES=""
for OUTPUT_FOLDER in run_physics_efficiency_output_*/ ; do 
  echo "==============================="
  echo "Entering ${OUTPUT_FOLDER}"
  cd ${OUTPUT_FOLDER}
  ls -1

  DIFF_FOUND=0
  DIFFS_THISFOLDER=""
  for i in $( ls ); do 
    echo "==============="
    echo " "
    echo " "
    echo "Checking ${i}"

    echo "Folder    : ${OUTPUT_FOLDER}"
    echo "File      : efficiency_${i}"
  
    FIRST=`grep -nr "Processing complete" ${i} | sed -e 's/\([0-9]*\).*/\1/'`
    NLINES=`wc -l ${i} | awk '{ print $1; }'`
    tail -n$((${NLINES}-${FIRST}-1)) ${i} | head -n$((${NLINES}-${FIRST}-3)) > efficiency_${i}
    cp efficiency_${i} ${TOPLEVEL}/generated_reference_files/${i}

    if [ ! -f "${TOPLEVEL}/test/reference/${i}" ]; then 
      echo "Reference : NOT FOUND - continue."
      continue
    else
      echo "Reference : test/reference/${i}"
      echo ""
    fi


    if ! diff -u -B -Z ${TOPLEVEL}/test/reference/${i} efficiency_${i}; then
      echo "***"
      echo "*** A difference was found."
      echo "***"
      diff -u -B -Z ${TOPLEVEL}/test/reference/${i} efficiency_${i} > ${i}.diff || true
      DIFF_FOUND=1
      DIFFS_THISFOLDER="${DIFFS_THISFOLDER}
      - ${OUTPUT_FOLDER}: ${i}"
    else
      echo "*** No differences found"
    fi
  done
  echo "---"
  if [ ${DIFF_FOUND} -ne 0 ]; then
    echo "*** Differences were found against reference files for ${OUTPUT_FOLDER}.";
    DIFFERENCES="${DIFFERENCES}
    ${DIFFS_THISFOLDER}"
    RC=3
  else
    echo "*** No differences found against reference files for ${OUTPUT_FOLDER}.";
  fi
  cd ${TOPLEVEL}
done 

if [ ${RC} -ne 0 ]; then 
  echo " "
  echo "*** Differences were found in efficiencies for:"
  echo "${DIFFERENCES}"
  echo " "
  echo "*** See above for diffs."
fi

exit ${RC}
