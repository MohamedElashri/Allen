#pragma once

#include "BinarySearch.cuh"
#include "SciFiEventModel.cuh"

// match stereo hits to x hits
__host__ __device__ bool binary_search_match_stereo_hit(
  const SciFi::Hits& scifi_hits,
  const int itUV1,
  const int uv_zone_offset_end,
  const float xMinUV,
  const float xMaxUV);
