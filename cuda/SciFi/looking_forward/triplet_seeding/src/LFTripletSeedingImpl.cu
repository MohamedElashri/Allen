#include "LFTripletSeedingImpl.cuh"
#include "BinarySearchTools.cuh"
#include "LookingForwardTools.cuh"

struct CombinedTripletValue {
  float chi2 = 10000.f;
  int16_t h0 = -1;
  int16_t h1 = -1;
  int16_t h2 = -1;
};

__device__ void lf_triplet_seeding_impl(
  const float* scifi_hits_x0,
  const uint layer_0,
  const uint layer_1,
  const uint layer_2,
  const int l0_start,
  const int l1_start,
  const int l2_start,
  const int l0_extrapolated,
  const int l1_extrapolated,
  const int l2_extrapolated,
  const int l0_size,
  const int l1_size,
  const int l2_size,
  const float z0,
  const float z1,
  const float z2,
  const float qop,
  const MiniState* ut_state,
  float* shared_partial_chi2,
  SciFi::TrackHits* scifi_tracks,
  uint* atomics_scifi,
  const LookingForward::Constants* dev_looking_forward_constants,
  const uint number_of_ut_track,
  const uint number_of_seeds)
{
  std::vector<CombinedTripletValue> best_combined;

  if (Configuration::verbosity_level >= logger::debug) {
    printf("---- Seeding of event %i with x layers {%i, %i, %i} ----\n", blockIdx.x,
      layer_0, layer_1, layer_2);
  }

  const auto tx = ut_state->tx;

  constexpr float p0 = -2.1156e-07f;  //   +/-   3.87224e-07
  constexpr float p1 = 0.000829677f;  //   +/-   4.70098e-06
  constexpr float p2 = -0.000174757f; //   +/-   1.00272e-05

  // // Required constants for the chi2 calculation below
  // const float zdiff = (z2 - z0) / (z1 - z0);
  // float extrap1 = LookingForward::get_extrap(qop, z1 - z0);
  // extrap1 *= extrap1;
  // const float extrap2 = LookingForward::get_extrap(qop, (z2 - z0));

  // Dumb search of best triplet
  for (int i = 0; i < l0_size; ++i) {
    const auto x0 = scifi_hits_x0[l0_start + i];

    for (int j = 0; j < l2_size; ++j) {
      const auto x2 = scifi_hits_x0[l2_start + j];
      // const auto partial_chi2 = x2 - x0 + x0 * zdiff - extrap2;

      const float slope_t1_t3 = (x0 - x2) / (z0 - z2);
      const float delta_slope = fabsf(tx - slope_t1_t3);
      const auto updated_qop = 1.f / (1.f / (p0 + p1 * delta_slope - p2 * delta_slope * delta_slope) + 5.08211e+02f);
      const auto expected_x1 = x0 + slope_t1_t3 * (z1 - z0) + 0.02528f + 13624.f * updated_qop;

      for (int k = 0; k < l1_size; ++k) {
        const auto x1 = scifi_hits_x0[l1_start + k];
        const auto chi2 = fabsf(expected_x1 - x1);

        if (chi2 < LookingForward::chi2_max_triplet_single) {
          best_combined.push_back(CombinedTripletValue {chi2, (int16_t) i, (int16_t) k, (int16_t) j});
        }
      }
    }
  }

  std::sort(
    best_combined.begin(), best_combined.end(), [](const CombinedTripletValue& a, const CombinedTripletValue& b) {
      return a.chi2 < b.chi2;
    });

  // Note: LookingForward::maximum_number_of_candidates_per_ut_track / number of seeds is the maximum that can be stored
  for (int i = 0;
       i < (LookingForward::maximum_number_of_candidates_per_ut_track / number_of_seeds) && i < best_combined.size();
       ++i) {
    const auto best_combo = best_combined[i];

    if (best_combo.h0 != -1) {
      const auto h0 = l0_start + best_combo.h0;
      const auto h1 = l1_start + best_combo.h1;
      const auto h2 = l2_start + best_combo.h2;

      const int insert_index = atomicAdd(atomics_scifi, 1);

      const auto l1_station = layer_1 / 2;
      const auto track = SciFi::TrackHits {
        h0,
        h1,
        h2,
        (uint16_t) layer_0,
        (uint16_t) layer_1,
        (uint16_t) layer_2,
        best_combo.chi2,
        LookingForward::qop_update_multi_par(
          *ut_state, scifi_hits_x0[h0], z0, scifi_hits_x0[h1], z1, l1_station, dev_looking_forward_constants),
        number_of_ut_track};
      scifi_tracks[insert_index] = track;

      if (Configuration::verbosity_level >= logger::debug) {
        track.print(blockIdx.x);
      }
    }
  }
}
