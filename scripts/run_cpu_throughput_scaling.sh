#!/bin/bash
###############################################################################
# (c) Copyright 2020 CERN for the benefit of the LHCb Collaboration           #
#                                                                             #
# This software is distributed under the terms of the GNU General Public      #
# Licence version 3 (GPL Version 3), copied verbatim in the file "COPYING".   #
#                                                                             #
# In applying this licence, CERN does not waive the privileges and immunities #
# granted to it by virtue of its status as an Intergovernmental Organization  #
# or submit itself to any jurisdiction.                                       #
###############################################################################

FOLDER=$1
if [ -z "$FOLDER" ]; then

  echo "Runs Allen throughput scaling on CPU, with a varying number of threads."
  echo "Usage: $0 <folder_containing_Allen_executable> [<output_folder>=output_'hostname'] [<data_directory>=/scratch/dcampora/allen_data/201907/minbias_mag_down]"

else

  OUTPUT_FOLDER=$2
  if [ -z "$OUTPUT_FOLDER" ]; then
    OUTPUT_FOLDER="output_`hostname`"
  fi

  DATA_DIRECTORY=$3
  if [ -z "$DATA_DIRECTORY" ]; then
    DATA_DIRECTORY="/scratch/dcampora/allen_data/201907/minbias_mag_down"
  fi

  mkdir ${OUTPUT_FOLDER}

  NUM_PROCESSORS=`lscpu | grep "CPU(s):" | head -n1 | awk '{ print $2 }'`
  NUM_NUMA_NODES=`lscpu | grep "NUMA node(s):" | awk '{ print $3 }'`
  ITERATIONS=$(($NUM_PROCESSORS / $NUM_NUMA_NODES))

  for i in `seq 1 ${ITERATIONS}`; do
    if [ $i -lt 3 ] || [ $(($i % 4)) -eq 0 ]; then
      echo "Running iteration ${i}/${ITERATIONS}..."
      numactl --cpunodebind=0 --membind=0 ${FOLDER}/Allen -f ${DATA_DIRECTORY} -n 200 -r 100 -c 0 -t $i > ${OUTPUT_FOLDER}/run_${i}.out
    fi
  done

  OUTPUT_FILE=${OUTPUT_FOLDER}/runs.csv
  touch $OUTPUT_FILE

  for i in `seq 1 ${ITERATIONS}`; do
    if [ $i -lt 3 ] || [ $(($i % 4)) -eq 0 ]; then
      value=`cat ${OUTPUT_FOLDER}/run_${i}.out | grep events/s | awk '{ print $1 }'`
      cores=$i

      echo $cores, $value >> $OUTPUT_FILE
    fi
  done

  echo "Generated $OUTPUT_FILE"

fi
