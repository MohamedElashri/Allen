#pragma once

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
  int r = array_size - 1;
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
  bool found = false;
  int l = 0;
  int r = array_size - 1;
  while (l < r) {
    const int m = (l + r) / 2;
    const auto array_element = array[m];

    // found |= std::abs(value - array_element) < margin;
    found |= comparator(value, array_element, m, margin);

    if (value - margin > array_element) {
      l = m + 1;
    }
    else {
      r = m;
    }
  }
  // found |= std::abs(value - array[l]) < margin;
  found |= comparator(value, array[l], l, margin);
  return found ? l : -1;
}

/**
 * @brief Finds the first candidate performing a binary search leftmost,
 *        with a configurable margin and the "<" compare function:
 *
 *        std::abs(value - array_element) < margin
 */
template<typename T>
__host__ __device__ int
binary_search_first_candidate(const T* array, const uint array_size, const T& value, const float margin)
{
  bool found = false;
  int l = 0;
  int r = array_size - 1;
  while (l < r) {
    const int m = (l + r) / 2;
    const auto array_element = array[m];
    found |= std::abs(value - array_element) < margin;
    if (value - margin > array_element) {
      l = m + 1;
    }
    else {
      r = m;
    }
  }
  found |= std::abs(value - array[l]) < margin;
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
  int r = array_size - 1;
  while (l < r) {
    const int m = (l + r) / 2;
    if (value + margin > array[m]) {
      l = m + 1;
    }
    else {
      r = m;
    }
  }
  const bool last_compatible = std::abs(value - array[l]) < margin;
  return last_compatible ? l + 1 : l;
}
