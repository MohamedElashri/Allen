#include "LFExtendTracksXImpl.cuh"

using namespace LookingForward;

__device__ void lf_extend_tracks_x_impl(
  const SciFi::Hits& scifi_hits,
  const short* scifi_lf_candidates,
  const int8_t number_of_candidates,
  SciFi::TrackHits& track,
  const float x0,
  const float x1,
  const float z0,
  const float z1,
  const float z2,
  const float max_chi2,
  const uint event_offset,
  bool* candidates_flag,
  const uint8_t relative_extrapolation_layer,
  const uint l_prev_offset,
  const uint l0_offset,
  const uint l1_offset,
  const uint extrapolation_layer_offset)
{
  // Precalculate chi2 related variables
  const auto dz1 = (z1 - z0);
  const auto dz2 = (z2 - z0);
  const auto tx = (x1 - x0) / dz1;
  float extrap1 = LookingForward::forward_param * track.qop * dz1 * dz1;
  extrap1 *= extrap1;
  const auto expected_x2 = x0 + tx * dz2 + LookingForward::forward_param * track.qop * dz2 * dz2;

  // Pick the best, according to chi2
  int8_t best_index = -1;
  float best_chi2 = max_chi2;

  for (int8_t h2_rel = 0; h2_rel < number_of_candidates; h2_rel++) {
    const auto x2 = scifi_hits.x0[event_offset + scifi_lf_candidates[h2_rel]];
    const auto chi2 = extrap1 + (x2 - expected_x2) * (x2 - expected_x2);

    if (chi2 < best_chi2) {
      best_chi2 = chi2;
      best_index = h2_rel;
    }
  }

  if (best_index != -1) {
    track.add_hit_with_candidate_and_quality(
      (uint16_t) scifi_lf_candidates[best_index],
      best_index,
      best_chi2);

    candidates_flag[l_prev_offset + track.hits[SciFi::Constants::hit_candidate_offset + track.hitsNum - 4]] = true;
    candidates_flag[l0_offset + track.hits[SciFi::Constants::hit_candidate_offset + track.hitsNum - 3]] = true;
    candidates_flag[l1_offset + track.hits[SciFi::Constants::hit_candidate_offset + track.hitsNum - 2]] = true;
    candidates_flag[extrapolation_layer_offset + track.hits[SciFi::Constants::hit_candidate_offset + track.hitsNum - 1]] = true;

    // const short index_to_check = 1446;
    // if ((track.hits[track.hitsNum - 4]) == index_to_check ||
    //   (track.hits[track.hitsNum - 3]) == index_to_check ||
    //   (track.hits[track.hitsNum - 2]) == index_to_check ||
    //   (track.hits[track.hitsNum - 1]) == index_to_check)
    // {
    //   printf("UT track %i, hits: %i, %i, %i, %i, candidates: %i, %i, %i, %i, offsets: %i, %i, %i, %i\n",
    //     current_ut_track_index,
    //     track.hits[track.hitsNum - 4],
    //     track.hits[track.hitsNum - 3],
    //     track.hits[track.hitsNum - 2],
    //     track.hits[track.hitsNum - 1],
    //     track.hits[SciFi::Constants::hit_candidate_offset + track.hitsNum - 4],
    //     track.hits[SciFi::Constants::hit_candidate_offset + track.hitsNum - 3],
    //     track.hits[SciFi::Constants::hit_candidate_offset + track.hitsNum - 2],
    //     track.hits[SciFi::Constants::hit_candidate_offset + track.hitsNum - 1],
    //     l_prev_offset,
    //     l0_offset,
    //     l1_offset,
    //     extrapolation_layer_offset
    //   );
    // }
  }
}
