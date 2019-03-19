#include "BinarySearchTools.cuh"

__host__ __device__ bool binary_search_match_stereo_hit(
  const SciFi::Hits& scifi_hits,
  const int itUV1,
  const int uv_zone_size,
  const float xMinUV,
  const float xMaxUV)
{
  const auto array = scifi_hits.x0 + itUV1;
  const int index = binary_search_leftmost(array, uv_zone_size, xMinUV);
  const auto value = array[index];

  return (value > xMinUV) && (value < xMaxUV);
}

// __host__ __device__ std::tuple<int, int> find_x_in_window(
//   const short* candidates,
//   const SciFi::Hits& hits,
//   const int num_hits,
//   const float value,
//   const float margin,
//   const int offset)
// {
//   int first_candidate = binary_search_first_candidate(candidates, num_hits, hits.x0, value, margin, offset);
//   int number_of_candidates = 0;

//   if (first_candidate != -1) {
//     number_of_candidates = binary_search_second_candidate(
//       candidates + first_candidate, num_hits - first_candidate, hits.x0, value, margin, offset);
//   }

//   return {first_candidate, number_of_candidates};
// }
