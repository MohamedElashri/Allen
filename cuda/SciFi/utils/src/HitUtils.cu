#include "HitUtils.cuh"

// match stereo hits to x hits
__host__ __device__ bool matchStereoHit(
  const int itUV1,
  const int uv_zone_offset_end,
  const SciFi::Hits& scifi_hits,
  const float xMinUV,
  const float xMaxUV)
{
  for (int stereoHit = itUV1; stereoHit != uv_zone_offset_end; ++stereoHit) {
    if (scifi_hits.x0[stereoHit] > xMinUV) {
      return (scifi_hits.x0[stereoHit] < xMaxUV);
    }
  }
  return false;
}
