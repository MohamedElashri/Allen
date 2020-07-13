#!/bin/bash

FOLDER=$1
if [ -eq $FOLDER ""]; then
  FOLDER="."
fi

OUTPUT_FOLDER=$2
if [ -eq $OUTPUT_FOLDER ""]; then
  OUTPUT_FOLDER="output_`hostname`"
fi

mkdir ${FOLDER}/${OUTPUT_FOLDER}

NUM_PROCESSORS=`lscpu | grep "CPU(s):" | head -n1 | awk '{ print $2 }'`
NUM_NUMA_NODES=`lscpu | grep "NUMA node(s):" | awk '{ print $3 }'`
ITERATIONS=$(($NUM_PROCESSORS / $NUM_NUMA_NODES))

for i in `seq 1 ${ITERATIONS}`; do
  echo "Running iteration ${i}/${ITERATIONS}..."

  numactl --cpunodebind=1 ${FOLDER}/Allen -f /scratch/dcampora/allen_data/201907/minbias_mag_down -n 200 -r 100 -c 0 -t $i > ${FOLDER}/${OUTPUT_FOLDER}/run_${i}.out
done

OUTPUT_FILE=${FOLDER}/${OUTPUT_FOLDER}/runs.csv
touch $OUTPUT_FILE

for i in `seq 1 ${ITERATIONS}`; do
  value=`cat ${OUTPUT_FOLDER}/run_${i}.out | grep events/s | awk '{ print $1 }'`
  cores=$i

  echo $cores, $value >> $OUTPUT_FILE
done

echo "Generated $OUTPUT_FILE"
