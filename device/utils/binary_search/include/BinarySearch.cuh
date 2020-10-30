/*****************************************************************************\
* (c) Copyright 2018-2020 CERN for the benefit of the LHCb Collaboration      *
\*****************************************************************************/
#pragma once

#include <cstdio>
#include "BackendCommon.h"

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

/**
 * @brief Linear search
 * @details This implementation of linear search accepts a parameter "start_element"
 *          which is the starting point of where to look for. The data structure
 *          is sweeped to the correct direction afterwards.
 */
template<typename T>
__host__ __device__ int
linear_search(const T* array, const int array_size, const T& value, const unsigned start_element = 0)
{
  // Start in start_element
  int i = start_element;
  const auto array_element = array[i];
  const auto direction = array_element > value;
  for (; i >= 0 && i < array_size; i += (direction ? -1 : 1)) {
    if ((!direction && array[i] > value) || (direction && array[i] < value)) {
      return i + direction;
    }
  }
  return i + direction;
}
