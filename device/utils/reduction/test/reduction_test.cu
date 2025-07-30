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

#include <iostream>
#include "BackendCommon.h"
#include "SumReduction.cuh"

bool verify_reduction(const unsigned seed)
{
  constexpr unsigned n_events = 1000;
  constexpr unsigned min_event_size = 4000;
  constexpr unsigned max_event_size = 8000;
  constexpr unsigned min_element = 100;
  constexpr unsigned max_element = 10000;
  std::srand(seed);

  // Generate random event sizes
  unsigned event_sizes_h[n_events];

  for (unsigned i = 0; i < n_events; i++) {
    unsigned event_size = min_event_size + std::rand() * (max_event_size - min_event_size) / RAND_MAX;
    event_sizes_h[i] = event_size;
  }

  // Produce offsets
  unsigned* offsets_h = nullptr;
  unsigned* offsets_d = nullptr;

  Allen::malloc_host((void**) &offsets_h, sizeof(unsigned) * (n_events + 1));
  Allen::malloc((void**) &offsets_d, sizeof(unsigned) * (n_events + 1));

  offsets_h[0] = 0;
  for (unsigned i = 1; i < n_events + 1; i++) {
    offsets_h[i] = offsets_h[i - 1] + event_sizes_h[i - 1];
  }
  const unsigned n_elements = offsets_h[n_events];

  Allen::memcpy((void*) offsets_d, (void*) offsets_h, sizeof(unsigned) * (n_events + 1), Allen::memcpyHostToDevice);

  // Produce random elements for each event
  unsigned* array_h = nullptr;
  unsigned* array_d = nullptr;

  Allen::malloc_host((void**) &array_h, sizeof(unsigned) * n_elements);
  Allen::malloc((void**) &array_d, sizeof(unsigned) * n_elements);

  for (unsigned evt = 0; evt < n_events; evt++) {
    unsigned offset = offsets_h[evt];
    unsigned event_size = offsets_h[evt + 1] - offset;
    unsigned* array = array_h + offset;
    for (unsigned i = 0; i < event_size; i++) {
      array[i] = min_element + std::rand() * (max_element - min_element) / RAND_MAX;
    }
  }

  Allen::memcpy((void*) array_d, (void*) array_h, sizeof(unsigned) * n_elements, Allen::memcpyHostToDevice);

  // Calculate sums
  unsigned* results_h = nullptr;
  unsigned* results_d = nullptr;

  Allen::malloc_host((void**) &results_h, sizeof(unsigned) * n_events);
  Allen::malloc((void**) &results_d, sizeof(unsigned) * n_events);

#ifndef TARGET_DEVICE_CPU
  constexpr unsigned block_size = 256;
  SumReduction::parallel_sum_reduction<unsigned><<<dim3(n_events), dim3(block_size)>>>(array_d, offsets_d, results_d);
#else
  for (unsigned evt = 0; evt < n_events; evt++) {
    unsigned offset = offsets_d[evt];
    unsigned event_size = offsets_d[evt + 1] - offset;
    unsigned* array = array_d + offset;
    results_d[evt] = 0;
    for (unsigned i = 0; i < event_size; i++) {
      results_d[evt] += array[i];
    }
  }
#endif

  Allen::memcpy((void*) results_h, (void*) results_d, sizeof(unsigned) * n_events, Allen::memcpyDeviceToHost);

  // Check results
  for (unsigned evt = 0; evt < n_events; evt++) {
    unsigned offset = offsets_h[evt];
    unsigned event_size = offsets_h[evt + 1] - offset;
    unsigned* array = array_h + offset;
    unsigned event_sum = 0;
    for (unsigned i = 0; i < event_size; i++) {
      event_sum += array[i];
    }
    if (event_sum != results_h[evt]) return false;
  }

  Allen::free_host(offsets_h);
  Allen::free(offsets_d);
  Allen::free_host(array_h);
  Allen::free(array_d);
  Allen::free_host(results_h);
  Allen::free(results_d);

  return true;
}

int main()
{
  for (unsigned s = 0; s < 20; s++) {
    if (verify_reduction(s)) {
      std::cout << "verify_reduction SUCCESSFUL for seed " << s << std::endl;
    }
    else {
      std::cout << "verify_reduction FAILED for seed " << s << std::endl;
    }
  }

  return 0;
}
