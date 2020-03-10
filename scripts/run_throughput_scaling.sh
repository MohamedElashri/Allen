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

# Run first iteration in case the number of NUMA nodes is greater than 1
if [ ${NUM_NUMA_NODES} -gt 1 ]; then
  echo "Running iteration 0/${ITERATIONS}..."
  numactl --cpunodebind=0 ${FOLDER}/Allen -f /scratch/dcampora/allen_data/201907/minbias_mag_down -n 1000 -r 10 -c 0 -t 1 > ${FOLDER}/${OUTPUT_FOLDER}/run_0_1.out
fi

for i in `seq 1 ${ITERATIONS}`; do
  echo "Running iteration ${i}/${ITERATIONS}..."

  for j in `seq 1 ${NUM_NUMA_NODES}`; do
    numactl --cpunodebind=$(($j - 1)) ${FOLDER}/Allen -f /scratch/dcampora/allen_data/201907/minbias_mag_down -n 1000 -r 10 -c 0 -t $i > ${FOLDER}/${OUTPUT_FOLDER}/run_${i}_${j}.out &
    pids[${j}]=$!
  done

  for pid in ${pids[*]}; do
    wait $pid
  done
done

OUTPUT_FILE=${FOLDER}/${OUTPUT_FOLDER}/runs.csv
touch $OUTPUT_FILE

if [ $((${NUM_NUMA_NODES})) -gt 1 ]; then
  value=`cat ${FOLDER}/${OUTPUT_FOLDER}/run_0_1.out | grep events/s | awk '{ print $1 }'`
  echo 1, $value >> $OUTPUT_FILE
fi

for i in `seq 1 ${ITERATIONS}`; do
  for j in `seq 1 ${NUM_NUMA_NODES}`; do
    values[${j}]=`cat ${OUTPUT_FOLDER}/run_${i}_${j}.out | grep events/s | awk '{ print $1 }'`
  done

  sum=0
  for value in ${values[*]}; do
    sum=`bc <<< "$sum + $value"`
  done

  cores=$(($i * ${NUM_NUMA_NODES}))

  echo $cores, $sum >> $OUTPUT_FILE
done

echo "Generated $OUTPUT_FILE"
