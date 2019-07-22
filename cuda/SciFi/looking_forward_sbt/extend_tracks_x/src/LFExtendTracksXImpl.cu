#include "LFExtendTracksXImpl.cuh"

using namespace LookingForward;

__device__ void lf_extend_tracks_x_impl(
  const float* scifi_hits_x0,
  const short* scifi_lf_candidates,
  const int8_t number_of_candidates,
  SciFi::TrackHits& track,
  const float x0,
  const float x1,
  const float z0,
  const float z1,
  const float z2,
  const float max_chi2)
{
  // Precalculate chi2 related variables
  const auto dz1 = (z1 - z0);
  const auto dz2 = (z2 - z0);
  const auto tx = (x1 - x0) / dz1;
  float extrap1 = LookingForward::get_extrap(track.qop, dz1);
  extrap1 *= extrap1;

  const auto expected_x2 = x0 + tx * dz2 + LookingForward::get_extrap(track.qop, dz2);

  // Pick the best, according to chi2
  int8_t best_index = -1;
  float best_chi2 = max_chi2;

  for (int8_t h2_rel = 0; h2_rel < number_of_candidates; h2_rel++) {
    const auto x2 = scifi_hits_x0[scifi_lf_candidates[h2_rel]];
    const auto chi2 = extrap1 + (x2 - expected_x2) * (x2 - expected_x2);

    if (chi2 < best_chi2) {
      best_chi2 = chi2;
      best_index = h2_rel;
    }
  }

  if (best_index != -1) {
    track.add_hit((uint16_t) scifi_lf_candidates[best_index]);
  }
}
