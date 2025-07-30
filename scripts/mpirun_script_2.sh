#!/bin/bash
###############################################################################
# (c) Copyright 2018-2020 CERN for the benefit of the LHCb Collaboration      #
#                                                                             #
# This software is distributed under the terms of the Apache License          #
# version 2 (Apache-2.0), copied verbatim in the file "LICENSE".              #
#                                                                             #
# In applying this licence, CERN does not waive the privileges and immunities #
# granted to it by virtue of its status as an Intergovernmental Organization  #
# or submit itself to any jurisdiction.                                       #
###############################################################################

ALLEN_RUN="../build/Allen  --mep /home/scratch/raaij/mep/upgrade_mc_minbias_scifi_v5_pf3000.mep --events-per-slice 1000 --non-stop 1 --with-mpi $1:1 -c 0 -v 3 -t 10 -s 18 --output-file tcp://192.168.1.101:35000 --device 81:00.0"

mpirun -host localhost -np 1 -x UCX_NET_DEVICES=$1:1 -oversubscribe -bind-to none -mca pml ucx -x UCX_TLS=rc_x hwloc-bind os=$1 $ALLEN_RUN \
     : -host localhost -np 1 -x UCX_NET_DEVICES=$2:1 -oversubscribe -bind-to none -mca pml ucx -x UCX_TLS=rc_x hwloc-bind os=$2 $ALLEN_RUN
