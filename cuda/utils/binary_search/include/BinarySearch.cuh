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
__host__ __device__ int binary_search_leftmost(const T* array, const uint array_size, const T& value)
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

template<typename T, typename R>
__host__ __device__ int
binary_search_leftmost(const T* index_array, const uint index_array_size, const R* data_array, const R& value)
{
  int l = 0;
  int r = index_array_size;
  while (l < r) {
    const int m = (l + r) / 2;
    const auto array_element = data_array[index_array[m]];
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
 * @brief Finds the first candidate performing a binary search leftmost,
 *        with a configurable margin and comparator.
 */
template<typename T, typename R>
__host__ __device__ int binary_search_first_candidate(
  const T* array,
  const uint array_size,
  const T& value,
  const float margin,
  const R& comparator)
{
  int l = 0;
  int r = array_size;
  while (l < r) {
    const int m = (l + r) / 2;
    const auto array_element = array[m];
    if (value - margin > array_element) {
      l = m + 1;
    }
    else {
      r = m;
    }
  }
  const bool found = (l != static_cast<int>(array_size)) && comparator(value, array[l], l, margin);
  return found ? l : -1;
}

/**
 * @brief Finds the first candidate performing a binary search leftmost,
 *        with a configurable margin and the "<" compare function:
 *
 *        fabsf(value - array_element) < margin
 */
template<typename T>
__host__ __device__ int
binary_search_first_candidate(const T* array, const uint array_size, const T& value, const float margin)
{
  int l = 0;
  int r = array_size;
  while (l < r) {
    const int m = (l + r) / 2;
    const auto array_element = array[m];
    if (value - margin > array_element) {
      l = m + 1;
    }
    else {
      r = m;
    }
  }
  const bool found = (l != static_cast<int>(array_size)) && (fabsf(value - array[l]) < margin);
  return found ? l : -1;
}

/**
 * @brief Finds a second candidate performing a binary search leftmost,
 *        with a configurable margin and the ">" compare function:
 *
 *        value + margin > array[m]
 */
template<typename T>
__host__ __device__ int
binary_search_second_candidate(const T* array, const uint array_size, const T& value, const float margin)
{
  int l = 0;
  int r = array_size;
  while (l < r) {
    const int m = (l + r) / 2;
    if (value + margin > array[m]) {
      l = m + 1;
    }
    else {
      r = m;
    }
  }
  return l;
}

/**
 * @brief Finds the first candidate performing a binary search leftmost,
 *        with a configurable margin and the "<" compare function:
 *
 *        fabsf(value - array_element) < margin
 */
template<typename T, typename R>
__host__ __device__ int binary_search_first_candidate(
  const T* index_array,
  const int index_array_size,
  const R* data_array,
  const R& value,
  const float margin,
  const int offset = 0)
{
  int l = 0;
  int r = index_array_size;
  while (l < r) {
    const int m = (l + r) / 2;
    const auto array_element = data_array[offset + index_array[m]];
    if (value - margin > array_element) {
      l = m + 1;
    }
    else {
      r = m;
    }
  }
  const bool found = (l != index_array_size) && (fabsf(value - data_array[index_array[l]]) < margin);
  return found ? l : -1;
}

/**
 * @brief Finds a second candidate performing a binary search leftmost,
 *        with a configurable margin and the ">" compare function:
 *
 *        value + margin > array[m]
 */
template<typename T, typename R>
__host__ __device__ int binary_search_second_candidate(
  const T* index_array,
  const int index_array_size,
  const R* data_array,
  const R& value,
  const float margin,
  const int offset = 0)
{
  int l = 0;
  int r = index_array_size;
  while (l < r) {
    const int m = (l + r) / 2;
    if (value + margin > data_array[offset + index_array[m]]) {
      l = m + 1;
    }
    else {
      r = m;
    }
  }
  return l;
}
