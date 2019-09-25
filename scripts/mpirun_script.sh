#!/bin/bash

#ALLEN_RUN="../build/Allen --mdf /localdisk/mep/upgrade_mc_minbias_scifi_v5_pf_1000.mep --non-stop 1 --with-mpi 1 -c 0 -v 5"
ALLEN_RUN="../build/Allen --mdf /localdisk/mep/upgrade_mc_minbias_scifi_v5_allmeps.mep --events-per-slice 3000 --non-stop 1 --with-mpi 1 -c 0 -v 5" 

mpirun -host localhost -x UCX_NET_DEVICES=$1:1 -oversubscribe -bind-to none -mca pml ucx -x UCX_TLS=rc_x hwloc-bind os=$1 $ALLEN_RUN : -host localhost -x UCX_NET_DEVICES=$2:1 -oversubscribe -bind-to none -mca pml ucx -x UCX_TLS=rc_x hwloc-bind os=$2 $ALLEN_RUN
