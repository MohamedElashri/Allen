#include "LFTripletSeedingImpl.cuh"
#include "BinarySearchTools.cuh"
#include "LookingForwardTools.cuh"

__device__ void lf_triplet_seeding_impl(
  const float* scifi_hits_x0,
  const uint layer_0,
  const uint layer_2,
  const int* initial_windows,
  const uint ut_total_number_of_tracks,
  const float qop,
  const float ut_tx,
  const float velo_tx,
  const float x_at_z_magnet,
  float* shared_x1,
  SciFi::CombinedValue* scifi_lf_triplet_best,
  const LookingForward::Constants* dev_looking_forward_constants)
{
  const auto z0 = dev_looking_forward_constants->Zone_zPos_xlayers[layer_0];
  const auto z2 = dev_looking_forward_constants->Zone_zPos_xlayers[layer_2];

  const int l0_start = initial_windows[(layer_0 * 8) * ut_total_number_of_tracks];
  const int l0_extrapolated = initial_windows[(layer_0 * 8 + 4) * ut_total_number_of_tracks];
  const int l0_size = initial_windows[(layer_0 * 8 + 1) * ut_total_number_of_tracks];

  const int l2_start = initial_windows[(layer_2 * 8) * ut_total_number_of_tracks];
  const int l2_extrapolated = initial_windows[(layer_2 * 8 + 4) * ut_total_number_of_tracks];
  const int l2_size = initial_windows[(layer_2 * 8 + 1) * ut_total_number_of_tracks];

  const auto inverse_dz2 = 1.f / (z0 - z2);

  const auto qop_range =
    fabsf(qop) > LookingForward::linear_range_qop_end ? 1.f : fabsf(qop) * (1.f / LookingForward::linear_range_qop_end);
  const auto opening_x_at_z_magnet_diff =
    LookingForward::x_at_magnet_range_0 +
    qop_range * (LookingForward::x_at_magnet_range_1 - LookingForward::x_at_magnet_range_0);

  const auto do_sign_check = fabsf(qop) > (1.f / LookingForward::sign_check_momentum_threshold);

  const int central_window_l0_begin = max(l0_extrapolated - LookingForward::extreme_layers_window_size / 2, 0);
  const int central_window_l0_size =
    min(central_window_l0_begin + LookingForward::extreme_layers_window_size, l0_size) - central_window_l0_begin;
  const int central_window_l2_begin = max(l2_extrapolated - LookingForward::extreme_layers_window_size / 2, 0);
  const int central_window_l2_size =
    min(central_window_l2_begin + LookingForward::extreme_layers_window_size, l2_size) - central_window_l2_begin;

  // Middle layers
  const auto layer_1 = layer_0 + 2;
  const auto z1 = dev_looking_forward_constants->Zone_zPos_xlayers[layer_1];

  const int l1_start = initial_windows[(layer_1 * 8) * ut_total_number_of_tracks];
  const int l1_extrapolated = initial_windows[(layer_1 * 8 + 4) * ut_total_number_of_tracks];
  const int l1_size = initial_windows[(layer_1 * 8 + 1) * ut_total_number_of_tracks];

  const int central_window_l1_begin = max(l1_extrapolated - LookingForward::middle_layer_window_size / 2, 0);
  const int central_window_l1_size =
    min(central_window_l1_begin + LookingForward::middle_layer_window_size, l1_size) - central_window_l1_begin;

  // Due to shared_x1
  __syncthreads();

  for (int i = threadIdx.x; i < central_window_l1_size; i += blockDim.x) {
    shared_x1[i] = scifi_hits_x0[l1_start + central_window_l1_begin + i];
  }

  // Due to shared_x1
  __syncthreads();

  constexpr int blockdim = 32;
  for (uint tid = threadIdx.x; tid < blockdim; tid += blockDim.x) {
    int best_index = -1;
    int best_h1 = -1;
    float best_chi2 = 100.f;

    // Treat central window iteration
    for (uint i = tid; i < central_window_l0_size * central_window_l2_size; i += blockdim) {
      const auto h0_rel = i % central_window_l0_size;
      const auto h2_rel = i / central_window_l0_size;

      const auto x0 = scifi_hits_x0[l0_start + central_window_l0_begin + h0_rel];
      const auto x2 = scifi_hits_x0[l2_start + central_window_l2_begin + h2_rel];

      // Extrapolation
      const auto slope_t1_t3 = (x0 - x2) * inverse_dz2;
      const auto delta_slope = fabsf(velo_tx - slope_t1_t3);
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

      const auto equal_signs_in_slopes = signbit(slope_t1_t3 - velo_tx) == signbit(ut_tx - velo_tx);
      const bool process_element =
        x_at_z_magnet_diff < opening_x_at_z_magnet_diff && (!do_sign_check || equal_signs_in_slopes);

      if (process_element) {
        for (uint j = 0; j < central_window_l1_size; ++j) {
          const auto expected_x1 = precalc_expected_x1 + z1 * slope_t1_t3;
          const auto x1 = shared_x1[j];
          const auto chi2 = (expected_x1 - x1) * (expected_x1 - x1);

          if (chi2 < best_chi2) {
            best_index = i;
            best_h1 = j;
            best_chi2 = chi2;
          }
        }
      }
    }

    if (best_h1 != -1) {
      scifi_lf_triplet_best[tid] =
        SciFi::CombinedValue {best_chi2,
                              (uint16_t)(l0_start + central_window_l0_begin + (best_index % central_window_l0_size)),
                              (uint16_t)(l1_start + central_window_l1_begin + best_h1),
                              (uint16_t)(l2_start + central_window_l2_begin + (best_index / central_window_l0_size))};
    }
  }
}
