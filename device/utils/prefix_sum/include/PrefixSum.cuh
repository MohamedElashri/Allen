#pragma once

#include "VeloEventModel.cuh"
#include "SciFiEventModel.cuh"
#include "UTEventModel.cuh"
#include "UTDefinitions.cuh"
#include "SciFiDefinitions.cuh"
#include "LookingForwardConstants.cuh"

__global__ void
  prefix_sum_reduce(uint* dev_main_array, uint* dev_auxiliary_array, const uint array_size);

__global__ void
  prefix_sum_single_block(uint* dev_total_sum, uint* dev_array, const uint array_size);

__global__ void
  prefix_sum_scan(uint* dev_main_array, uint* dev_auxiliary_array, const uint array_size);
