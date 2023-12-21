#!/bin/bash
###############################################################################
# (c) Copyright 2022 CERN for the benefit of the LHCb Collaboration           #
###############################################################################

nvidia-smi -i 0 -f power_measurement.csv -lms 100 --query-gpu=index,timestamp,power.draw --format=csv & $1

sleep 1


# wait
