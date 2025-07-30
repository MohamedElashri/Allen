/*****************************************************************************\
* (c) Copyright 2024 CERN for the benefit of the LHCb Collaboration      *
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

namespace SumReduction {
  template<typename T>
  __global__ void parallel_sum_reduction(const T* dev_input_buffer, const unsigned* dev_offsets, T* dev_output_buffer);

  template<typename Alg, typename T>
  void sum_reduction(
    const Alg& alg,
    const Allen::Context& context,
    const T* dev_input_buffer,
    const unsigned* dev_offsets,
    const unsigned n_events,
    T* dev_output_buffer)
  {
#ifdef TARGET_DEVICE_CPU
    constexpr unsigned block_size = 1;
#else
    constexpr unsigned block_size = 256;
#endif
    alg.global_function(parallel_sum_reduction<T>)(dim3(n_events), dim3(block_size), context)(
      dev_input_buffer, dev_offsets, dev_output_buffer);

    Allen::synchronize(context);
  }
} // namespace SumReduction
