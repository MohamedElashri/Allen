#include "BinarySearchTools.cuh"

__host__ __device__ bool binary_search_match_stereo_hit(
  SciFi::ConstHits& scifi_hits,
  const int itUV1,
  const int uv_zone_size,
  const float xMinUV,
  const float xMaxUV)
{
  const auto array = scifi_hits.x0_p(itUV1);
  const int index = binary_search_leftmost(array, uv_zone_size, xMinUV);
  const auto value = array[index];

  return (index != uv_zone_size) && (value > xMinUV) && (value < xMaxUV);
}
