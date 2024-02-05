/*****************************************************************************\
* (c) Copyright 2018-2020 CERN for the benefit of the LHCb Collaboration      *
*                                                                             *
* This software is distributed under the terms of the Apache License          *
* version 2 (Apache-2.0), copied verbatim in the file "LICENSE".              *
*                                                                             *
* In applying this licence, CERN does not waive the privileges and immunities *
* granted to it by virtue of its status as an Intergovernmental Organization  *
* or submit itself to any jurisdiction.                                       *
\*****************************************************************************/
#pragma once

#include "BackendCommon.h"
#include "VeloEventModel.cuh"
#include "SciFiEventModel.cuh"
#include "UTEventModel.cuh"

__global__ void prefix_sum_reduce(unsigned* dev_main_array, unsigned* dev_auxiliary_array, const unsigned array_size);

__global__ void prefix_sum_single_block(unsigned* dev_total_sum, unsigned* dev_array, const unsigned array_size);

__global__ void prefix_sum_scan(unsigned* dev_main_array, unsigned* dev_auxiliary_array, const unsigned array_size);
