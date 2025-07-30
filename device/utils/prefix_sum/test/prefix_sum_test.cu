/*****************************************************************************\
* (c) Copyright 2018-2024 CERN for the benefit of the LHCb Collaboration      *
*                                                                             *
* This software is distributed under the terms of the Apache License          *
* version 2 (Apache-2.0), copied verbatim in the file "LICENSE".              *
*                                                                             *
* In applying this licence, CERN does not waive the privileges and immunities *
* granted to it by virtue of its status as an Intergovernmental Organization  *
* or submit itself to any jurisdiction.                                       *
\*****************************************************************************/
#include <iostream>
#include <iomanip>
#include <chrono>
#include "PrefixSum.cuh"
#include "BackendCommon.h"

template<typename F>
bool verify_prefix_sum(unsigned size, F&& prefix_sum)
{
  unsigned* array_h = nullptr;
  unsigned* array_d = nullptr;

  Allen::malloc_host((void**) &array_h, sizeof(unsigned) * (size + 2));
  Allen::malloc((void**) &array_d, sizeof(unsigned) * (size + 2));

  // Allocate 2 scratch buffers device and host, should cover the need of all implementations
  unsigned* scratch_h = nullptr;
  unsigned* scratch_d = nullptr;
  Allen::malloc_host((void**) &scratch_h, sizeof(unsigned) * (size + 2));
  Allen::malloc((void**) &scratch_d, sizeof(unsigned) * (size + 2));

  for (unsigned i = 0; i < size; i++) {
    array_h[i] = 1;
  }
  array_h[size] = 0;
  array_h[size + 1] = 0xbebebebe; // guard for out of bound checks
  Allen::memcpy((void*) array_d, (void*) array_h, sizeof(unsigned) * (size + 2), Allen::memcpyHostToDevice);

  prefix_sum(array_d, size, scratch_h, scratch_d);

  Allen::memcpy((void*) array_h, (void*) array_d, sizeof(unsigned) * (size + 2), Allen::memcpyDeviceToHost);
  Allen::free(array_d);

  if (size == 100) {
    for (unsigned i = 0; i <= size; i++) {
      printf("%d ", array_h[i]);
    }
    printf("\n");
  }

  Allen::free_host(scratch_h);
  Allen::free(scratch_d);

  for (unsigned i = 0; i <= size; i++) {
    if (array_h[i] != i) {
      Allen::free_host(array_h);
      return false;
    }
  }
  if (array_h[size + 1] != 0xbebebebe) {
    std::cout << "Guard check failed" << std::endl;
    Allen::free_host(array_h);
    return false;
  }
  Allen::free_host(array_h);
  return true;
}

template<typename F>
double benchmark_prefix_sum(unsigned size, F&& prefix_sum, unsigned n_repetitions = 1000)
{
  unsigned* array_d = nullptr;
  Allen::malloc((void**) &array_d, sizeof(unsigned) * (size + 1));

  unsigned* scratch_h = nullptr;
  unsigned* scratch_d = nullptr;
  Allen::malloc_host((void**) &scratch_h, sizeof(unsigned) * (size + 1));
  Allen::malloc((void**) &scratch_d, sizeof(unsigned) * (size + 1));

  const auto start = std::chrono::high_resolution_clock::now();
  for (unsigned i = 0; i < n_repetitions; i++) {
    prefix_sum(array_d, size, scratch_h, scratch_d);

#ifndef TARGET_DEVICE_CPU
    cudaDeviceSynchronize();
#endif
  }
  const auto end = std::chrono::high_resolution_clock::now();
  const std::chrono::duration<double> diff = end - start;

  Allen::free(array_d);
  Allen::free_host(scratch_h);
  Allen::free(scratch_d);

  return diff.count() / n_repetitions;
}

void prefix_sum_cpu1(
  unsigned* array_d,
  unsigned array_size,
  [[maybe_unused]] unsigned* scratch_h,
  [[maybe_unused]] unsigned* scratch_d)
{
  unsigned* array_h = scratch_h;
  Allen::memcpy((void*) array_h, (void*) array_d, sizeof(unsigned) * (array_size + 1), Allen::memcpyDeviceToHost);

  unsigned sum = 0;
  for (unsigned i = 0; i < array_size + 1; i++) {
    unsigned val = array_h[i];
    array_h[i] = sum;
    sum += val;
  }

  Allen::memcpy((void*) array_d, (void*) array_h, sizeof(unsigned) * (array_size + 1), Allen::memcpyHostToDevice);
}

#ifndef TARGET_DEVICE_CPU
void prefix_sum_cuda1(
  unsigned* array_d,
  unsigned array_size,
  [[maybe_unused]] unsigned* scratch_h,
  [[maybe_unused]] unsigned* scratch_d)
{
  constexpr unsigned block_size = 256;
  constexpr unsigned elements_per_thread = 1;
  unsigned n_blocks = (array_size + (block_size * elements_per_thread) - 1) / (block_size * elements_per_thread);

  unsigned* prefix_sum_aux_array = scratch_d;

  PrefixSum::prefix_sum_reduce_x1<<<dim3(n_blocks), dim3(block_size / 2)>>>(array_d, prefix_sum_aux_array, array_size);

  PrefixSum::prefix_sum_single_block<<<dim3(1), dim3(block_size / 2)>>>(prefix_sum_aux_array, n_blocks);

  PrefixSum::prefix_sum_scan<<<dim3(n_blocks), dim3(block_size * elements_per_thread)>>>(
    array_d, prefix_sum_aux_array, array_size + 1);
}

void prefix_sum_cuda2(
  unsigned* array_d,
  unsigned array_size,
  [[maybe_unused]] unsigned* scratch_h,
  [[maybe_unused]] unsigned* scratch_d)
{
  constexpr unsigned block_size = 256;
  constexpr unsigned elements_per_thread = 4;
  unsigned n_blocks = (array_size + (block_size * elements_per_thread) - 1) / (block_size * elements_per_thread);

  unsigned* prefix_sum_aux_array = scratch_d;

  PrefixSum::prefix_sum_reduce<<<dim3(n_blocks), dim3(block_size / 2)>>>(array_d, prefix_sum_aux_array, array_size);

  PrefixSum::prefix_sum_single_block<<<dim3(1), dim3(block_size / 2)>>>(prefix_sum_aux_array, n_blocks);

  PrefixSum::prefix_sum_scan<<<dim3(n_blocks), dim3(block_size * elements_per_thread)>>>(
    array_d, prefix_sum_aux_array, array_size + 1);
}

void prefix_sum_cuda3(
  unsigned* array_d,
  unsigned array_size,
  [[maybe_unused]] unsigned* scratch_h,
  [[maybe_unused]] unsigned* scratch_d)
{
  constexpr unsigned block_size = 256;

  PrefixSum::prefix_sum_single_block<<<dim3(1), dim3(block_size / 2)>>>(array_d, array_size);
}

void prefix_sum_cuda4(
  unsigned* array_d,
  unsigned array_size,
  [[maybe_unused]] unsigned* scratch_h,
  [[maybe_unused]] unsigned* scratch_d)
{
  PrefixSum::prefix_sum_single_warp<<<dim3(1), dim3(32)>>>(array_d, array_size);
}

void prefix_sum_cuda5(
  unsigned* array_d,
  unsigned array_size,
  [[maybe_unused]] unsigned* scratch_h,
  [[maybe_unused]] unsigned* scratch_d)
{
  PrefixSum::prefix_sum_single_warp_x4<<<dim3(1), dim3(32)>>>(array_d, array_size, nullptr);
}
#endif

#define TEST(x)                                                      \
  if (verify_prefix_sum(size, x)) {                                  \
    std::cout << #x << " SUCCESSFUL for size " << size << std::endl; \
  }                                                                  \
  else {                                                             \
    std::cout << #x << " FAILED for size " << size << std::endl;     \
  }

int main()
{
  for (unsigned size = 10; size <= 1000000; size = size * 10) {
    TEST(prefix_sum_cpu1)
#ifndef TARGET_DEVICE_CPU
    TEST(prefix_sum_cuda1)
    TEST(prefix_sum_cuda2)
    TEST(prefix_sum_cuda3)
    TEST(prefix_sum_cuda4)
    TEST(prefix_sum_cuda5)
#endif
    std::cout << std::endl;
  }
  for (unsigned size = 1; size <= 1024; size = size * 2) {
    TEST(prefix_sum_cpu1)
#ifndef TARGET_DEVICE_CPU
    TEST(prefix_sum_cuda1)
    TEST(prefix_sum_cuda2)
    TEST(prefix_sum_cuda3)
    TEST(prefix_sum_cuda4)
    TEST(prefix_sum_cuda5)
#endif
    std::cout << std::endl;
  }

  std::cout << "\nsize      cpu1         cuda1        cuda2        cuda3        cuda4        cuda5" << std::endl;
  for (unsigned size = 10; size <= 10000000; size = size * 2) {
    std::cout << std::setw(9) << size << " " << std::scientific;
    std::cout << benchmark_prefix_sum(size, prefix_sum_cpu1) << " ";
#ifndef TARGET_DEVICE_CPU
    std::cout << benchmark_prefix_sum(size, prefix_sum_cuda1) << " ";
    std::cout << benchmark_prefix_sum(size, prefix_sum_cuda2) << " ";
    std::cout << benchmark_prefix_sum(size, prefix_sum_cuda3) << " ";
    std::cout << benchmark_prefix_sum(size, prefix_sum_cuda4) << " ";
    std::cout << benchmark_prefix_sum(size, prefix_sum_cuda5) << " ";
#endif
    std::cout << std::endl;
  }

  return 0;
}
