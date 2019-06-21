#pragma once

#include "SciFiDefinitions.cuh"
#include "SciFiEventModel.cuh"

// match stereo hits to x hits
__host__ __device__ bool matchStereoHit(
  const int itUV1,
  const int uv_zone_offset_end,
  const SciFi::Hits& scifi_hits,
  const float xMinUV,
  const float xMaxUV);

// check that val is within [min, max]
__host__ __device__ inline bool isInside(float val, const float min, const float max)
{
  return (val > min) && (val < max);
}

// get lowest index where range[index] > value, within [start,end] of range
__host__ __device__ inline int getLowerBound(float range[], float value, int start, int end)
{
  int i = start;
  for (; i < end; i++) {
    if (range[i] > value) break;
  }
  return i;
}
