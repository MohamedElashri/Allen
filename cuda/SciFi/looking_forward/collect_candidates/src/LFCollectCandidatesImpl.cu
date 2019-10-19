#include "LFCollectCandidatesImpl.cuh"
#include "BinarySearchTools.cuh"
#include "LookingForwardTools.cuh"

__device__ void lf_collect_candidates_impl(
  const SciFi::Hits& scifi_hits,
  const int* initial_windows,
  const int number_of_tracks,
  uint* number_of_candidates,
  short* candidates,
  const int event_offset)
{
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

    int j = window_size / 2;
    for (int n = 0; n < window_size && candidate_counter < LookingForward::maximum_number_of_candidates; ++n) {
      if (n & 0x1) {
        j -= n;
      }
      else {
        j += n;
      }

      const auto hit_index = window_start + j;
      const auto xHit = scifi_hits.x0[hit_index];

      const auto delta_x = (-xHit + param_uv_x_mag);
      const auto xHitInUv = LookingForward::linear_propagation(xHit, delta_x, param_uv_dz_ratio);
      const auto xHitInUvCorr = xHitInUv - param_uv_corr;

      const float maxDx = (window_size > 64) ? param_uv_dx : param_uv_dx * 2.f;
      const auto xMinUV = xHitInUvCorr - maxDx;
      const auto xMaxUV = xHitInUvCorr + maxDx;

      if (binary_search_match_stereo_hit(scifi_hits, search_window_start, search_window_size, xMinUV, xMaxUV)) {
        candidates[i * LookingForward::maximum_number_of_candidates + candidate_counter++] =
          (short) (hit_index - event_offset);
      }
    }
    number_of_candidates[i] = candidate_counter;
  }
}
