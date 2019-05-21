#include "LFCollectCandidatesImpl.cuh"
#include "BinarySearchTools.cuh"
#include "LookingForwardTools.cuh"

__device__ void lf_collect_candidates_impl(
  const SciFi::Hits& scifi_hits,
  const int* initial_windows,
  const float qop,
  const int number_of_tracks,
  uint* number_of_candidates,
  short* candidates,
  const int event_offset,
  const int event_number_of_hits)
{
  float* initial_windows_f = (float*) &initial_windows[0];
  for (int i = threadIdx.y; i < LookingForward::number_of_x_layers; i += blockDim.y) {
    const auto window_start = initial_windows[i * 8 * number_of_tracks];
    const auto window_size = initial_windows[(i * 8 + 1) * number_of_tracks];
    const auto search_window_start = initial_windows[(i * 8 + 2) * number_of_tracks];
    const auto search_window_size = initial_windows[(i * 8 + 3) * number_of_tracks];
    const auto param_uv_0 = initial_windows_f[(i * 8 + 4) * number_of_tracks];
    const auto param_uv_1 = initial_windows_f[(i * 8 + 5) * number_of_tracks];
    const auto param_uv_2 = initial_windows_f[(i * 8 + 6) * number_of_tracks];
    const auto param_uv_3 = initial_windows_f[(i * 8 + 7) * number_of_tracks];
    uint8_t candidate_counter = 0;

    for (int j = 0; j < window_size && candidate_counter < LookingForward::maximum_number_of_candidates; ++j) {
      const auto hit_index = window_start + j;
      const auto xHit = scifi_hits.x0[hit_index];

      const auto xPredUv = param_uv_0 + xHit * param_uv_1;
      const auto maxDx = param_uv_2 + std::abs(xHit - param_uv_3) * SciFi::Tracking::tolYSlopeCollectX;

      // Note: Making a tighter requirement on the UV layer hit
      const auto multiplier = (event_number_of_hits > 5500) ? 0.8f : 1.f;
      const auto xMinUV = xPredUv - maxDx * multiplier;
      const auto xMaxUV = xPredUv + maxDx * multiplier;
      
      // const float maxDx = 25.f + 6e5f * std::abs(qop);
      // //const float xPredUV = param_uv_0;
      // const float xMinUV = (xHit - maxDx);
      // const float xMaxUV = (xHit + maxDx);

      if (binary_search_match_stereo_hit(
            scifi_hits,
            search_window_start,
            search_window_size,
            xMinUV,
            xMaxUV)) {
        candidates[i * LookingForward::maximum_number_of_candidates + candidate_counter++] =
            (short) (hit_index - event_offset);
      }
    }

    number_of_candidates[i] = candidate_counter;
  }
}

__device__ void lf_collect_candidates_p_impl(
    const SciFi::Hits& scifi_hits,
    const int* initial_windows,
    const float qop,
    const int number_of_tracks,
    uint* number_of_candidates,
    short* candidates,
    const int event_offset,
    const int event_number_of_hits){

  float* initial_windows_f = (float*) &initial_windows[0];
  for (int i = threadIdx.y; i < LookingForward::number_of_x_layers; i += blockDim.y) {
    const auto window_start = initial_windows[i * 8 * number_of_tracks];
    const auto window_size = initial_windows[(i * 8 + 1) * number_of_tracks];
    const auto search_window_start = initial_windows[(i * 8 + 2) * number_of_tracks];
    const auto search_window_size = initial_windows[(i * 8 + 3) * number_of_tracks];
    const auto param_uv_x_mag = initial_windows_f[(i * 8 + 4) * number_of_tracks];
    const auto param_uv_corr = initial_windows_f[(i * 8 + 5) * number_of_tracks];
    const auto param_uv_dx = initial_windows_f[(i * 8 + 6) * number_of_tracks];
    const auto param_uv_dz_ratio = initial_windows_f[(i * 8 + 7) * number_of_tracks];
    uint8_t candidate_counter = 0;

//    if(window_size > LookingForward::maximum_number_of_candidates){
//      printf("BIG window %d / %d\n", window_size, LookingForward::maximum_number_of_candidates);
//    }
    for (int j = 0; j < window_size && candidate_counter < LookingForward::maximum_number_of_candidates; ++j) {
      const auto hit_index = window_start + j;
      const auto xHit = scifi_hits.x0[hit_index];

      const auto delta_x = (-xHit + param_uv_x_mag);
      const auto xHitInUv = LookingForward::linear_propagation(xHit, delta_x , param_uv_dz_ratio);
      const auto xHitInUvCorr = xHitInUv - param_uv_corr;
      const float maxDx = param_uv_dx*2;//5;
      const auto xMinUV = xHitInUvCorr - maxDx;
      const auto xMaxUV = xHitInUvCorr + maxDx;

      // const float maxDx = 25.f + 6e5f * std::abs(qop);
      // //const float xPredUV = param_uv_0;
      // const float xMinUV = (xHit - maxDx);
      // const float xMaxUV = (xHit + maxDx);

      if (binary_search_match_stereo_hit(
            scifi_hits,
            search_window_start,
            search_window_size,
            xMinUV,
            xMaxUV)) {
        candidates[i * LookingForward::maximum_number_of_candidates + candidate_counter++] =
            (short) (hit_index - event_offset);
      }
    }

    number_of_candidates[i] = candidate_counter;
  }


}
