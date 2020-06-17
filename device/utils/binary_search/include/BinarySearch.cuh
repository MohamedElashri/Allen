#pragma once

#include <cstdio>
#include "CudaCommon.h"

/**
 * @brief  Binary search leftmost
 * @detail This implementation finds the "leftmost element",
 *         as described in
 *         https://en.wikipedia.org/wiki/Binary_search_algorithm
 */
template<typename T>
__host__ __device__ int binary_search_leftmost(const T* array, const unsigned array_size, const T& value)
{
  int l = 0;
  int r = array_size;
  while (l < r) {
    const int m = (l + r) / 2;
    const auto array_element = array[m];
    if (value > array_element) {
      l = m + 1;
    }
    else {
      r = m;
    }
  }
  return l;
}
