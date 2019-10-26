#include "LFTripletSeedingImpl.cuh"
#include "BinarySearchTools.cuh"
#include "LookingForwardTools.cuh"

__device__ void lf_triplet_seeding_impl(
  const float* scifi_hits_x0,
  const float z0,
  const float z1,
  const float z2,
  const int l0_start,
  const int l1_start,
  const int l2_start,
  const int l0_size,
  const int l1_size,
  const int l2_size,
  const int central_window_l0_begin,
  const int central_window_l1_begin,
  const int central_window_l2_begin,
  const int* initial_windows,
  const uint ut_total_number_of_tracks,
  const float qop,
  const float ut_tx,
  const float velo_tx,
  const float x_at_z_magnet,
  float* shared_x1,
  float* scifi_lf_triplet_best)
{
  const auto inverse_dz2 = 1.f / (z0 - z2);

  const auto qop_range =
    fabsf(qop) > LookingForward::linear_range_qop_end ? 1.f : fabsf(qop) * (1.f / LookingForward::linear_range_qop_end);
  const auto opening_x_at_z_magnet_diff =
    LookingForward::x_at_magnet_range_0 +
    qop_range * (LookingForward::x_at_magnet_range_1 - LookingForward::x_at_magnet_range_0);

  const auto do_sign_check = fabsf(qop) > (1.f / LookingForward::sign_check_momentum_threshold);

  const int central_window_l0_size =
    min(central_window_l0_begin + LookingForward::extreme_layers_window_size, l0_size) - central_window_l0_begin;
  const int central_window_l1_size =
    min(central_window_l1_begin + LookingForward::middle_layer_window_size, l1_size) - central_window_l1_begin;
  const int central_window_l2_size =
    min(central_window_l2_begin + LookingForward::extreme_layers_window_size, l2_size) - central_window_l2_begin;

  // Due to shared_x1
  __syncthreads();

  for (int i = threadIdx.x; i < central_window_l1_size; i += blockDim.x) {
    shared_x1[i] = scifi_hits_x0[l1_start + central_window_l1_begin + i];
  }

  // Due to shared_x1
  __syncthreads();

  constexpr int blockdim = 32;
  for (uint tid = threadIdx.x; tid < blockdim; tid += blockDim.x) {
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
        constexpr int local_l1_size = 12;

        const auto mean1 = h0_rel / ((float) central_window_l0_size);
        const auto mean2 = h2_rel / ((float) central_window_l2_size);
        const int l1_extrap = (mean1 + mean2) * 0.5f * central_window_l1_size;
        const auto local_central_window_l1_begin = max(l1_extrap - local_l1_size / 2, 0);
        const auto local_central_window_l1_end = min(local_central_window_l1_begin + local_l1_size, central_window_l1_size);

        float best_chi2 = LookingForward::chi2_max_triplet_single;
        int best_j = -1;

        for (uint j = local_central_window_l1_begin; j < local_central_window_l1_end; ++j) {
          const auto expected_x1 = precalc_expected_x1 + z1 * slope_t1_t3;
          const auto x1 = shared_x1[j];
          const auto chi2 = (expected_x1 - x1) * (expected_x1 - x1);

          if (chi2 < best_chi2) {
            best_chi2 = chi2;
            best_j = j;
          }
        }

        if (best_j != -1) {
          // if (Configuration::verbosity_level >= logger::debug) {
          //   printf("Best triplet found: %i, %i, %i, %f\n", h0_rel, h2_rel, best_j, best_chi2);
          // }

          // Encode j into chi2
          int* best_chi2_int = reinterpret_cast<int*>(&best_chi2);
          best_chi2_int[0] = (best_chi2_int[0] & 0xFFFFFFE0) + best_j;

          // Store chi2 with encoded j
          scifi_lf_triplet_best[h0_rel * LookingForward::extreme_layers_window_size + h2_rel] = best_chi2;
        }
      }
    }
  }
}
