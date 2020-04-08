#!/bin/bash

ALLEN_RUN="../build/Allen --mep /home/scratch/raaij/mep/upgrade_mc_minbias_scifi_v5_pf3000.mep --events-per-slice 1000 --non-stop 1 --with-mpi $1:2,$2:1 -c 0 -v 3 -t 10 -s 18 --output-file tcp://192.168.1.101:35000 --device 01:00.0"

mpirun -host localhost -np 1 -x UCX_NET_DEVICES=$1:1,$2:1 -x UCX_SELF_DEVICES= -oversubscribe -bind-to none -mca pml ucx -x UCX_TLS=rc_x hwloc-bind --cpubind os=$1 --membind os=$1 --mempolicy default $ALLEN_RUN \
     : -host localhost -np 1 -x UCX_NET_DEVICES=$1:1 -x UCX_SELF_DEVICES= -oversubscribe -bind-to none -mca pml ucx -x UCX_TLS=rc_x hwloc-bind --cpubind os=$2 --membind os=$2 $ALLEN_RUN \
     : -host localhost -np 1 -x UCX_NET_DEVICES=$2:1 -x UCX_SELF_DEVICES= -oversubscribe -bind-to none -mca pml ucx -x UCX_TLS=rc_x hwloc-bind --cpubind os=$2 --membind os=$2 $ALLEN_RUN
