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

#include "AlgorithmTypes.cuh"
#include "BackendCommon.h"

namespace PrefixSum {

#ifndef TARGET_DEVICE_CPU
  __global__ void prefix_sum_reduce(unsigned* dev_array, unsigned* dev_auxiliary_array, const unsigned array_size);

  __global__ void prefix_sum_single_block(unsigned* dev_array, const unsigned array_size);

  __global__ void prefix_sum_scan(unsigned* dev_array, unsigned* dev_auxiliary_array, const unsigned array_size);
#endif

  template<typename Alg, typename Args>
  void prefix_sum(
    [[maybe_unused]] const Alg& alg,
    [[maybe_unused]] const Args& arguments,
    [[maybe_unused]] const Allen::Context& context,
    unsigned* dev_array,
    const unsigned array_size)
  {
#if defined(TARGET_DEVICE_CPU)
    unsigned sum = 0;
    for (unsigned i = 0; i < array_size + 1; i++) {
      unsigned val = dev_array[i];
      dev_array[i] = sum;
      sum += val;
    }
#else
    constexpr unsigned block_size = 256;
    constexpr unsigned elements_per_thread = 4;
    unsigned n_blocks = (array_size + (block_size * elements_per_thread) - 1) / (block_size * elements_per_thread);

    auto prefix_sum_aux_array = arguments.template make_buffer<Allen::Store::Scope::Device, unsigned>(n_blocks + 1);
    Allen::memset_async(prefix_sum_aux_array.data(), 0, (n_blocks + 1) * sizeof(unsigned), context);

    alg.global_function(prefix_sum_reduce)(dim3(n_blocks), dim3(block_size / 2), context)(
      dev_array, prefix_sum_aux_array.data(), array_size);

    alg.global_function(prefix_sum_single_block)(dim3(1), dim3(block_size / 2), context)(
      prefix_sum_aux_array.data(), n_blocks);

    alg.global_function(prefix_sum_scan)(dim3(n_blocks), dim3(block_size * elements_per_thread), context)(
      dev_array, prefix_sum_aux_array.data(), array_size + 1);
#endif
  }
} // namespace PrefixSum