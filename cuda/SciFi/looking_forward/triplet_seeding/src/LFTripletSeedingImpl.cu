#include "LFTripletSeedingImpl.cuh"
#include "BinarySearchTools.cuh"
#include "LookingForwardTools.cuh"

__device__ void lf_triplet_seeding_impl(
  const float* scifi_hits_x0,
  const int layer_0,
  const int layer_1,
  const int layer_2,
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
  float* shared_precalc_expected_x1,
  SciFi::TrackHits* scifi_tracks,
  uint* atomics_scifi,
  const LookingForward::Constants* dev_looking_forward_constants,
  const uint number_of_ut_track,
  const uint number_of_seeds,
  const MiniState& velo_state,
  SciFi::CombinedValue* scifi_lf_triplet_best)
{
  // if (Configuration::verbosity_level >= logger::debug) {
  //   printf(
  //     "---- Seeding of event %i, UT track %i with x layers {%i, %i, %i} ----\n",
  //     blockIdx.x,
  //     number_of_ut_track,
  //     layer_0,
  //     layer_1,
  //     layer_2);
  // }

  const auto inverse_dz2 = 1.f / (z0 - z2);

  // Extrapolation: Renato's extrapolation
  const auto tx = velo_state.tx;

  const auto x_at_z_magnet = velo_state.x + (LookingForward::z_magnet - velo_state.z) * velo_state.tx;

  const auto qop_range =
    fabsf(qop) > LookingForward::linear_range_qop_end ? 1.f : fabsf(qop) * (1.f / LookingForward::linear_range_qop_end);
  const auto opening_x_at_z_magnet_diff =
    LookingForward::x_at_magnet_range_0 +
    qop_range * (LookingForward::x_at_magnet_range_1 - LookingForward::x_at_magnet_range_0);

  const auto do_sign_check = fabsf(qop) > (1.f / LookingForward::sign_check_momentum_threshold);

  const int central_window_l0_begin = max(l0_extrapolated - LookingForward::extreme_layers_window_size / 2, 0);
  const int central_window_l0_size = min(central_window_l0_begin + LookingForward::extreme_layers_window_size, l0_size) - central_window_l0_begin;
  const int central_window_l1_begin = max(l1_extrapolated - LookingForward::middle_layer_window_size / 2, 0);
  const int central_window_l1_size = min(central_window_l1_begin + LookingForward::middle_layer_window_size, l1_size) - central_window_l1_begin;
  const int central_window_l2_begin = max(l2_extrapolated - LookingForward::extreme_layers_window_size / 2, 0);
  const int central_window_l2_size = min(central_window_l2_begin + LookingForward::extreme_layers_window_size, l2_size) - central_window_l2_begin;

  // Due to shared_precalc_expected_x1
  __syncthreads();

  for (int i = threadIdx.x; i < 32 * 32; i += blockDim.x) {
    shared_precalc_expected_x1[i] = 100000.f;
  }

  // Due to shared_precalc_expected_x1
  __syncthreads();

  // Treat central window iteration
  for (uint h0_rel = 0; h0_rel < central_window_l0_size; ++h0_rel) {
    const auto x0 = scifi_hits_x0[l0_start + central_window_l0_begin + h0_rel];

    // Due to shared_precalc_expected_x1
    __syncthreads();

    for (uint h2_rel = 0; h2_rel < central_window_l2_size; ++h2_rel) {
      const auto x2 = scifi_hits_x0[l2_start + central_window_l2_begin + h2_rel];

      // Extrapolation
      const auto slope_t1_t3 = (x0 - x2) * inverse_dz2;
      const auto delta_slope = fabsf(tx - slope_t1_t3);
      const auto eq = LookingForward::qop_p0 + LookingForward::qop_p1 * delta_slope -
                      LookingForward::qop_p2 * delta_slope * delta_slope;
      const auto updated_qop = eq / (1.f + 5.08211e+02f * eq);
      const auto precalc_expected_x1 = x0 - slope_t1_t3 * z0 + 0.02528f + 13624.f * updated_qop;

      const auto track_x_at_z_magnet = x0 + (LookingForward::z_magnet - z0) * slope_t1_t3;
      const auto x_at_z_magnet_diff = fabsf(
        track_x_at_z_magnet - x_at_z_magnet -
        (LookingForward::x_at_z_p0 + LookingForward::x_at_z_p1 * slope_t1_t3 +
         LookingForward::x_at_z_p2 * slope_t1_t3 * slope_t1_t3 +
         LookingForward::x_at_z_p3 * slope_t1_t3 * slope_t1_t3 * slope_t1_t3));

      const auto equal_signs_in_slopes = signbit(slope_t1_t3 - tx) == signbit(ut_state->tx - tx);
      const bool process_element =
        x_at_z_magnet_diff < opening_x_at_z_magnet_diff && (!do_sign_check || equal_signs_in_slopes);

      shared_precalc_expected_x1[h0_rel + h2_rel* 32] = process_element ? precalc_expected_x1 + z1 * slope_t1_t3 : 100000.f;
    }

    // Due to shared_precalc_expected_x1
    __syncthreads();
  }

  for (uint h1_rel = threadIdx.x; h1_rel < central_window_l1_size; h1_rel += blockDim.x) {
    const auto l1_element = central_window_l1_begin + h1_rel;

    int best_index = -1;
    float best_chi2 = 100.f;

    const auto x1 = scifi_hits_x0[l1_start + l1_element];

    // Iterate all elements in shared_precalc_expected_x1
    for (uint k = threadIdx.x; k < 32 * 32; ++k) {
      // Note: For this, we would need to save the slope_t1_t3 as well
      // const auto expected_x1 = precalc_expected_x1 + z1 * slope_t1_t3;
      const auto expected_x1 = shared_precalc_expected_x1[k];
      const auto chi2 = (expected_x1 - x1) * (expected_x1 - x1);

      if (chi2 < best_chi2) {
        best_index = k;
        best_chi2 = chi2;
      }
    }

    if (best_index != -1 && best_chi2 < scifi_lf_triplet_best[h1_rel].chi2) {
      // printf(
      //   "Best seed for h1_rel : %i, %f; better than %f\n",
      //   h1_rel,
      //   best_index,
      //   best_chi2,
      //   scifi_lf_triplet_best[h1_rel].chi2);

      scifi_lf_triplet_best[h1_rel] =
        SciFi::CombinedValue {best_chi2, (int16_t)(best_index % 32), (int16_t)(best_index / 32)};
    }

    // if (chi2 < best_combined[k - central_window_l1_begin].chi2) {
    //   best_combined_second[k - central_window_l1_begin] = best_combined[k - central_window_l1_begin];
    //   best_combined[k - central_window_l1_begin] =
    //     CombinedTripletValue {chi2, (int16_t) i, (int16_t) k, (int16_t) j};
    // }
    // else if (chi2 < best_combined_second[k - central_window_l1_begin].chi2) {
    //   best_combined_second[k - central_window_l1_begin] =
    //     CombinedTripletValue {chi2, (int16_t) i, (int16_t) k, (int16_t) j};
    // }
  }
}
