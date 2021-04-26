#!/usr/bin/bash
###############################################################################
# (c) Copyright 2018-2020 CERN for the benefit of the LHCb Collaboration      #
###############################################################################

set -euo pipefail

TOPLEVEL=$(realpath ${PWD})

echo "Sequence: ${SEQUENCE}"

ls run_with_run_changes_output_${SEQUENCE}
ls run_no_run_changes_output_${SEQUENCE}
cd run_with_run_changes_output_${SEQUENCE}

for i in $( ls ); do 
  echo "Checking ${i}"; 
  FIRST=`grep -nr "Processing complete" ${i} | sed -e 's/\([0-9]*\).*/\1/'`; 
  NLINES=`wc -l ${i} | awk '{ print $1; }'`; 
  tail -n$((${NLINES}-${FIRST}-1)) ${i} | head -n$((${NLINES}-${FIRST}-3)) > run_changes_${i}; 
  tail -n$((${NLINES}-${FIRST}-1)) ${TOPLEVEL}/run_no_run_changes_output_${SEQUENCE}/${i} | head -n$((${NLINES}-${FIRST}-3)) > no_run_changes_${i}; 
  diff -u no_run_changes_${i} run_changes_${i} | tee ${i}_diff || true; 
done

cat *_diff > alldiffs

if [ -s alldiffs ]; then 
  echo "Differences were found against output without run change splitting."
  exit 3
else
  echo "No differences found against output without run change splitting."
  exit 0
fi
