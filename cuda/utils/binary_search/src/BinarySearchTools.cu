#include "BinarySearchTools.cuh"

__host__ __device__ bool binary_search_match_stereo_hit(
  const SciFi::Hits& scifi_hits,
  const int itUV1,
  const int uv_zone_offset_end,
  const float xMinUV,
  const float xMaxUV)
{
  const auto array = scifi_hits.x0 + itUV1;
  const auto array_size = uv_zone_offset_end - itUV1;
  const int index = binary_search_leftmost(array, array_size, xMinUV);
  const auto value = array[index];

  return (value > xMinUV) && (value < xMaxUV);
}
