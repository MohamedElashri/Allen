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
#include "PrefixSum.cuh"

__global__ void prefix_sum_scan(unsigned* dev_main_array, unsigned* dev_auxiliary_array, const unsigned array_size)
{
  // Note: The first block is already correctly populated.
  //       Start on the second block.
  const unsigned element = (blockIdx.x + 1) * blockDim.x + threadIdx.x;

  if (element < array_size) {
    const unsigned cluster_offset = dev_auxiliary_array[blockIdx.x + 1];
    dev_main_array[element] += cluster_offset;
  }
}
