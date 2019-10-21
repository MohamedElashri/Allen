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
  std::vector<CombinedTripletValue> best_combined;

  if (Configuration::verbosity_level >= logger::debug) {
    printf("---- Seeding of event %i with x layers {%i, %i, %i} ----\n", blockIdx.x, layer_0, layer_1, layer_2);
  }

  // Extrapolation: Renato's extrapolation
  const auto tx = velo_state.tx;
  constexpr float p0 = -2.1156e-07f;  //   +/-   3.87224e-07
  constexpr float p1 = 0.000829677f;  //   +/-   4.70098e-06
  constexpr float p2 = -0.000174757f; //   +/-   1.00272e-05

  const auto x_at_z_magnet = velo_state.x + (LookingForward::z_magnet - velo_state.z) * velo_state.tx;

  constexpr float x_at_z_p0 = 0.300706f;
  constexpr float x_at_z_p1 = 14.814f;
  constexpr float x_at_z_p2 = -29.8856f;
  constexpr float x_at_z_p3 = -440.203f;

  constexpr float linear_range_qop_end = 0.0005f;
  constexpr float x_at_magnet_range [2] {8.f, 40.f};

  const auto qop_range = fabsf(qop) > linear_range_qop_end ? 1.f : fabsf(qop) * (1.f / linear_range_qop_end);
  const auto opening_x_at_z_magnet_diff = x_at_magnet_range[0] + qop_range * (x_at_magnet_range[1] - x_at_magnet_range[0]);

  constexpr float do_sign_check_momentum_threshold = 5000.f;
  const auto do_sign_check = fabsf(qop) > (1.f / do_sign_check_momentum_threshold);

  // printf("qop %f, qop_range %f, opening_x_at_z_magnet_diff %f\n",
  //   qop, qop_range, opening_x_at_z_magnet_diff);

  // printf(
  //   "\nExtrapolated and sizes: {%i, %i}, {%i, %i}, {%i, %i}\n",
  //   l0_extrapolated,
  //   l0_size,
  //   l1_extrapolated,
  //   l1_size,
  //   l2_extrapolated,
  //   l2_size);

  constexpr int sliding_window_max_iterations = 0;
  constexpr int extreme_layers_window_size = 32;
  constexpr int middle_layer_window_size = 64;

  const int central_window_l0[2] {max(l0_extrapolated - extreme_layers_window_size / 2, 0),
                                  min(l0_extrapolated + extreme_layers_window_size / 2, l0_size)};
  const int central_window_l1[2] {max(l1_extrapolated - middle_layer_window_size / 2, 0),
                                  min(l1_extrapolated + middle_layer_window_size / 2, l1_size)};
  const int central_window_l2[2] {max(l2_extrapolated - extreme_layers_window_size / 2, 0),
                                  min(l2_extrapolated + extreme_layers_window_size / 2, l2_size)};

  // Treat central window iteration
  for (uint i = central_window_l0[0]; i < central_window_l0[1]; ++i) {
    const auto x0 = scifi_hits_x0[l0_start + i];

    for (uint j = central_window_l2[0]; j < central_window_l2[1]; ++j) {
      const auto x2 = scifi_hits_x0[l2_start + j];

      // Extrapolation
      const float slope_t1_t3 = (x0 - x2) / (z0 - z2);
      const float delta_slope = fabsf(tx - slope_t1_t3);
      const auto updated_qop = 1.f / (1.f / (p0 + p1 * delta_slope - p2 * delta_slope * delta_slope) + 5.08211e+02f);
      const auto expected_x1 = x0 + slope_t1_t3 * (z1 - z0) + 0.02528f + 13624.f * updated_qop;

      const auto track_x_at_z_magnet = x0 + (LookingForward::z_magnet - z0) * slope_t1_t3;
      const auto x_at_z_magnet_diff = fabsf(track_x_at_z_magnet - x_at_z_magnet -
          (x_at_z_p0 + x_at_z_p1 * slope_t1_t3 + x_at_z_p2 * slope_t1_t3 * slope_t1_t3 +
           x_at_z_p3 * slope_t1_t3 * slope_t1_t3 * slope_t1_t3));

      const auto equal_signs_in_slopes = signbit(slope_t1_t3 - tx) == signbit(ut_state->tx - tx);

      if (x_at_z_magnet_diff < opening_x_at_z_magnet_diff && (!do_sign_check || equal_signs_in_slopes)) {
        for (uint k = central_window_l1[0]; k < central_window_l1[1]; ++k) {
          const auto x1 = scifi_hits_x0[l1_start + k];
          const auto chi2 = fabsf(expected_x1 - x1);

          if (chi2 < LookingForward::chi2_max_triplet_single) {
            // printf("chi2 %f, x_at_z_magnet diff %f\n", chi2, x_at_z_magnet_diff);
            best_combined.push_back(CombinedTripletValue {chi2, (int16_t) i, (int16_t) k, (int16_t) j});
          }
        }
      }
    }
  }

  // printf(
  //   " Starting windows: {%i, %i}, {%i, %i}, {%i, %i}\n",
  //   central_window_l0[0],
  //   central_window_l0[1],
  //   central_window_l1[0],
  //   central_window_l1[1],
  //   central_window_l2[0],
  //   central_window_l2[1]);

  // Iterate to the left
  int left_window_l0[2] {central_window_l0[0], central_window_l0[1]};
  int left_window_l1[2] {central_window_l1[0], central_window_l1[1]};
  int left_window_l2[2] {central_window_l2[0], central_window_l2[1]};
  int left_iterations = 0;
  while ((left_window_l0[0] != 0 || left_window_l2[0] != 0) && left_iterations < sliding_window_max_iterations) {
    ++left_iterations;

    if (left_window_l0[0] != 0) {
      left_window_l0[1] = left_window_l0[0];
      left_window_l0[0] = max(left_window_l0[0] - extreme_layers_window_size, 0);
    }

    if (left_window_l2[0] != 0) {
      left_window_l2[1] = left_window_l2[0];
      left_window_l2[0] = max(left_window_l2[0] - extreme_layers_window_size, 0);
    }

    if (left_window_l1[0] != 0) {
      // Note: l1 window size is overlapping with
      // with previous l1 window size. This is intentional.
      left_window_l1[1] = left_window_l1[0];
      left_window_l1[0] = max(left_window_l1[0] - extreme_layers_window_size, 0);
    }

    for (uint i = left_window_l0[0]; i < left_window_l0[1]; ++i) {
      const auto x0 = scifi_hits_x0[l0_start + i];

      for (uint j = left_window_l2[0]; j < left_window_l2[1]; ++j) {
        const auto x2 = scifi_hits_x0[l2_start + j];

        // Extrapolation 1
        // const auto partial_chi2 = x2 - x0 + x0 * zdiff - extrap2;

        // Extrapolation 2
        const float slope_t1_t3 = (x0 - x2) / (z0 - z2);
        const float delta_slope = fabsf(tx - slope_t1_t3);
        const auto updated_qop = 1.f / (1.f / (p0 + p1 * delta_slope - p2 * delta_slope * delta_slope) + 5.08211e+02f);
        const auto expected_x1 = x0 + slope_t1_t3 * (z1 - z0) + 0.02528f + 13624.f * updated_qop;

        for (uint k = left_window_l1[0]; k < left_window_l1[1]; ++k) {
          const auto x1 = scifi_hits_x0[l1_start + k];

          // Extrapolation 1
          // auto chi2 = partial_chi2 - x1 * zdiff;
          // chi2 = extrap1 + chi2 * chi2;

          // Extrapolation 2
          const auto chi2 = fabsf(expected_x1 - x1);

          if (chi2 < LookingForward::chi2_max_triplet_single) {
            best_combined.push_back(CombinedTripletValue {chi2, (int16_t) i, (int16_t) k, (int16_t) j});
          }
        }
      }
    }

    // printf(
    //   " Left windows: {%i, %i}, {%i, %i}, {%i, %i}\n",
    //   left_window_l0[0],
    //   left_window_l0[1],
    //   left_window_l1[0],
    //   left_window_l1[1],
    //   left_window_l2[0],
    //   left_window_l2[1]);
  }

  // Iterate to the right
  int right_window_l0[2] {central_window_l0[0], central_window_l0[1]};
  int right_window_l1[2] {central_window_l1[0], central_window_l1[1]};
  int right_window_l2[2] {central_window_l2[0], central_window_l2[1]};
  int right_iterations = 0;
  while ((right_window_l0[1] != l0_size || right_window_l2[1] != l2_size) &&
         right_iterations < sliding_window_max_iterations) {
    ++right_iterations;

    if (right_window_l0[1] != l0_size) {
      right_window_l0[0] = right_window_l0[1];
      right_window_l0[1] = min(right_window_l0[1] + extreme_layers_window_size, l0_size);
    }

    if (right_window_l2[1] != l2_size) {
      right_window_l2[0] = right_window_l2[1];
      right_window_l2[1] = min(right_window_l2[1] + extreme_layers_window_size, l2_size);
    }

    if (right_window_l1[1] != l1_size) {
      // Note: l1 window size is overlapping with
      // with previous l1 window size. This is intentional.
      right_window_l1[0] = right_window_l1[1];
      right_window_l1[1] = min(right_window_l1[1] + extreme_layers_window_size, l1_size);
    }

    for (uint i = right_window_l0[0]; i < right_window_l0[1]; ++i) {
      const auto x0 = scifi_hits_x0[l0_start + i];

      for (uint j = right_window_l2[0]; j < right_window_l2[1]; ++j) {
        const auto x2 = scifi_hits_x0[l2_start + j];

        // Extrapolation 1
        // const auto partial_chi2 = x2 - x0 + x0 * zdiff - extrap2;

        // Extrapolation 2
        const float slope_t1_t3 = (x0 - x2) / (z0 - z2);
        const float delta_slope = fabsf(tx - slope_t1_t3);
        const auto updated_qop = 1.f / (1.f / (p0 + p1 * delta_slope - p2 * delta_slope * delta_slope) + 5.08211e+02f);
        const auto expected_x1 = x0 + slope_t1_t3 * (z1 - z0) + 0.02528f + 13624.f * updated_qop;

        for (uint k = right_window_l1[0]; k < right_window_l1[1]; ++k) {
          const auto x1 = scifi_hits_x0[l1_start + k];

          // Extrapolation 1
          // auto chi2 = partial_chi2 - x1 * zdiff;
          // chi2 = extrap1 + chi2 * chi2;

          // Extrapolation 2
          const auto chi2 = fabsf(expected_x1 - x1);

          if (chi2 < LookingForward::chi2_max_triplet_single) {
            best_combined.push_back(CombinedTripletValue {chi2, (int16_t) i, (int16_t) k, (int16_t) j});
          }
        }
      }
    }

    // printf(
    //   " Right windows: {%i, %i}, {%i, %i}, {%i, %i}\n",
    //   right_window_l0[0],
    //   right_window_l0[1],
    //   right_window_l1[0],
    //   right_window_l1[1],
    //   right_window_l2[0],
    //   right_window_l2[1]);
  }

  // // Dumb search of best triplet
  // for (int i = 0; i < l0_size; ++i) {
  //   const auto x0 = scifi_hits_x0[l0_start + i];

  //   for (int j = 0; j < l2_size; ++j) {
  //     const auto x2 = scifi_hits_x0[l2_start + j];
  //     // const auto partial_chi2 = x2 - x0 + x0 * zdiff - extrap2;

  //     const float slope_t1_t3 = (x0 - x2) / (z0 - z2);
  //     const float delta_slope = fabsf(tx - slope_t1_t3);
  //     const auto updated_qop = 1.f / (1.f / (p0 + p1 * delta_slope - p2 * delta_slope * delta_slope) + 5.08211e+02f);
  //     const auto expected_x1 = x0 + slope_t1_t3 * (z1 - z0) + 0.02528f + 13624.f * updated_qop;

  //     for (int k = 0; k < l1_size; ++k) {
  //       const auto x1 = scifi_hits_x0[l1_start + k];
  //       const auto chi2 = fabsf(expected_x1 - x1);

  //       if (chi2 < LookingForward::chi2_max_triplet_single) {
  //         best_combined.push_back(CombinedTripletValue {chi2, (int16_t) i, (int16_t) k, (int16_t) j});
  //       }
  //     }
  //   }
  // }

  std::sort(
    best_combined.begin(), best_combined.end(), [](const CombinedTripletValue& a, const CombinedTripletValue& b) {
      return a.chi2 < b.chi2;
    });

  // Note: LookingForward::maximum_number_of_candidates_per_ut_track / number of seeds is the maximum that can be stored
  for (int i = 0;
       i < (LookingForward::maximum_number_of_candidates_per_ut_track / number_of_seeds) && i < best_combined.size();
       ++i) {
    const auto best_combo = best_combined[i];

    if (best_combo.h0 != 1) {
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
