#!/bin/bash

ALLEN_RUN="./Allen --mdf `find /scratch/dcampora/allen_data/201907/mdf -path "*.mdf" -print0 | sort -z | tr '\0' ',' | sed 's/.$//'` --non-stop 1"

mpirun -host localhost -x UCX_NET_DEVICES=$1:1 -oversubscribe -bind-to none -mca pml ucx -x UCX_TLS=rc_x hwloc-bind os=$1 $ALLEN_RUN : -host localhost -x UCX_NET_DEVICES=$2:1 -oversubscribe -bind-to none -mca pml ucx -x UCX_TLS=rc_x hwloc-bind os=$2 $ALLEN_RUN
