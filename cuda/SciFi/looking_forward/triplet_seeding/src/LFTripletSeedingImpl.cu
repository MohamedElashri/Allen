#include "LFTripletSeedingImpl.cuh"
#include "BinarySearchTools.cuh"
#include "LookingForwardTools.cuh"

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
  const uint number_of_seeds,
  const MiniState& velo_state)
{
  if (Configuration::verbosity_level >= logger::debug) {
    printf("---- Seeding of event %i with x layers {%i, %i, %i} ----\n", blockIdx.x, layer_0, layer_1, layer_2);
  }

  // Extrapolation: Renato's extrapolation
  const auto tx = velo_state.tx;
  constexpr float p0 = -2.1156e-07f;
  constexpr float p1 = 0.000829677f;
  constexpr float p2 = -0.000174757f;

  const auto x_at_z_magnet = velo_state.x + (LookingForward::z_magnet - velo_state.z) * velo_state.tx;

  constexpr float x_at_z_p0 = -0.819493;
  constexpr float x_at_z_p1 = 19.3897;
  constexpr float x_at_z_p2 = 16.6874;
  constexpr float x_at_z_p3 = -375.478;

  constexpr float linear_range_qop_end = 0.0005f;
  constexpr float x_at_magnet_range[2] {8.f, 40.f};

  const auto qop_range = fabsf(qop) > linear_range_qop_end ? 1.f : fabsf(qop) * (1.f / linear_range_qop_end);
  const auto opening_x_at_z_magnet_diff =
    x_at_magnet_range[0] + qop_range * (x_at_magnet_range[1] - x_at_magnet_range[0]);

  constexpr float do_sign_check_momentum_threshold = 5000.f;
  const auto do_sign_check = fabsf(qop) > (1.f / do_sign_check_momentum_threshold);

  constexpr int extreme_layers_window_size = 32;
  constexpr int middle_layer_window_size = 64;

  const int central_window_l0_begin = max(l0_extrapolated - extreme_layers_window_size / 2, 0);
  const int central_window_l0_end = min(central_window_l0_begin + extreme_layers_window_size, l0_size);
  const int central_window_l1_begin = max(l1_extrapolated - middle_layer_window_size / 2, 0);
  const int central_window_l1_end = min(central_window_l1_begin + middle_layer_window_size, l1_size);
  const int central_window_l2_begin = max(l2_extrapolated - extreme_layers_window_size / 2, 0);
  const int central_window_l2_end = min(central_window_l2_begin + extreme_layers_window_size, l2_size);

  // std::vector<CombinedTripletValue> best_combined;
  CombinedTripletValue best_combined[middle_layer_window_size];
  CombinedTripletValue best_combined_second[middle_layer_window_size];

  // Treat central window iteration
  for (int i = central_window_l0_begin; i < central_window_l0_end; ++i) {
    const auto x0 = scifi_hits_x0[l0_start + i];

    for (int j = central_window_l2_begin; j < central_window_l2_end; ++j) {
      const auto x2 = scifi_hits_x0[l2_start + j];

      // Extrapolation
      const auto slope_t1_t3 = (x0 - x2) / (z0 - z2);
      const auto delta_slope = fabsf(tx - slope_t1_t3);
      const auto updated_qop = 1.f / (1.f / (p0 + p1 * delta_slope - p2 * delta_slope * delta_slope) + 5.08211e+02f);
      const auto expected_x1 = x0 + slope_t1_t3 * (z1 - z0) + 0.02528f + 13624.f * updated_qop;

      const auto track_x_at_z_magnet = x0 + (LookingForward::z_magnet - z0) * slope_t1_t3;
      const auto x_at_z_magnet_diff = fabsf(
        track_x_at_z_magnet - x_at_z_magnet -
        (x_at_z_p0 + x_at_z_p1 * slope_t1_t3 + x_at_z_p2 * slope_t1_t3 * slope_t1_t3 +
         x_at_z_p3 * slope_t1_t3 * slope_t1_t3 * slope_t1_t3));

      const auto equal_signs_in_slopes = signbit(slope_t1_t3 - tx) == signbit(ut_state->tx - tx);

      if (x_at_z_magnet_diff < opening_x_at_z_magnet_diff && (!do_sign_check || equal_signs_in_slopes)) {
        for (int k = central_window_l1_begin; k < central_window_l1_end; ++k) {
          const auto x1 = scifi_hits_x0[l1_start + k];
          const auto chi2 = (expected_x1 - x1) * (expected_x1 - x1);

          if (chi2 < best_combined[k - central_window_l1_begin].chi2) {
            best_combined_second[k - central_window_l1_begin] = best_combined[k - central_window_l1_begin];
            best_combined[k - central_window_l1_begin] = CombinedTripletValue {chi2, (int16_t) i, (int16_t) k, (int16_t) j};
          }
          else if (chi2 < best_combined_second[k - central_window_l1_begin].chi2) {
            best_combined_second[k - central_window_l1_begin] = CombinedTripletValue {chi2, (int16_t) i, (int16_t) k, (int16_t) j};
          }
        }
      }
    }
  }

  std::array<CombinedTripletValue, 2 * middle_layer_window_size> best_combined_array;
  for (uint i = 0; i < middle_layer_window_size; ++i) {
    best_combined_array[i] = best_combined[i];
    best_combined_array[middle_layer_window_size + i] = best_combined_second[i];
  }

  std::sort(
    best_combined_array.begin(), best_combined_array.end(), [](const CombinedTripletValue& a, const CombinedTripletValue& b) {
      return a.chi2 < b.chi2;
    });

  constexpr int maximum_number_of_candidates_per_ut_track_half = 20;

  // Note: LookingForward::maximum_number_of_candidates_per_ut_track / number of seeds is the maximum that can be stored
  for (int i = 0; i < maximum_number_of_candidates_per_ut_track_half; ++i) {
    const auto best_combo = best_combined_array[i];
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
        (uint16_t) number_of_ut_track};
      scifi_tracks[insert_index] = track;

      if (Configuration::verbosity_level >= logger::debug) {
        track.print(blockIdx.x);
      }
    }
  }
}
