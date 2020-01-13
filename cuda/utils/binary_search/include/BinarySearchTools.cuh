#pragma once

#include <tuple>
#include "BinarySearch.cuh"
#include "SciFiEventModel.cuh"

// match stereo hits to x hits
__host__ __device__ bool binary_search_match_stereo_hit(
  const SciFi::Hits<const char>& scifi_hits,
  const int itUV1,
  const int uv_zone_offset_end,
  const float xMinUV,
  const float xMaxUV);

template<class T>
__host__ __device__ std::tuple<int, int> find_x_in_window(
  const T* candidates,
  const SciFi::Hits<const char>& hits,
  const int num_hits,
  const float value,
  const float margin,
  const int offset = 0)
{
  int first_candidate = binary_search_first_candidate(candidates, num_hits, hits.x0, value, margin, offset);
  int number_of_candidates = 0;

  if (first_candidate != -1) {
    number_of_candidates = binary_search_second_candidate(
      candidates + first_candidate, num_hits - first_candidate, hits.x0, value, margin, offset);
  }

  return std::tuple<int, int> {first_candidate, number_of_candidates};
}
