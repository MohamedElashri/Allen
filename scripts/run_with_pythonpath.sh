#!/bin/sh
###############################################################################
# (c) Copyright 2018-2020 CERN for the benefit of the LHCb Collaboration      #
###############################################################################

PREPEND_PYTHON_PATH=$1
shift
PYTHONPATH=${PREPEND_PYTHON_PATH}:${PYTHONPATH} $@
