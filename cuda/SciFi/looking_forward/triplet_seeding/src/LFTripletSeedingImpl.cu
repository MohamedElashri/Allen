#include "LFTripletSeedingImpl.cuh"
#include "BinarySearchTools.cuh"
#include "LookingForwardTools.cuh"

__device__ void lf_triplet_seeding_impl(
  const float* scifi_hits_x0,
  const uint layer_0,
  const uint layer_1,
  const uint layer_2,
  const int l0_size,
  const int l1_size,
  const int l2_size,
  const float z0,
  const float z1,
  const float z2,
  const int* initial_windows,
  const uint ut_track_number,
  const uint ut_total_number_of_tracks,
  const float qop,
  const float ut_tx,
  const float velo_tx,
  const float x_at_z_magnet,
  float* shared_x1,
  float* scifi_lf_triplet_best,
  int16_t* scifi_lf_found_triplets,
  int16_t* scifi_lf_number_of_found_triplets,
  const uint triplet_seed)
{
  const int l0_start = initial_windows[(layer_0 * 8) * ut_total_number_of_tracks];
  const int l0_extrapolated = initial_windows[(layer_0 * 8 + 4) * ut_total_number_of_tracks];

  const int l1_start = initial_windows[(layer_1 * 8) * ut_total_number_of_tracks];
  const int l1_extrapolated = initial_windows[(layer_1 * 8 + 4) * ut_total_number_of_tracks];

  const int l2_start = initial_windows[(layer_2 * 8) * ut_total_number_of_tracks];
  const int l2_extrapolated = initial_windows[(layer_2 * 8 + 4) * ut_total_number_of_tracks];

  const int central_window_l0_begin = max(l0_extrapolated - LookingForward::extreme_layers_window_size / 2, 0);
  const int central_window_l1_begin = max(l1_extrapolated - LookingForward::middle_layer_window_size / 2, 0);
  const int central_window_l2_begin = max(l2_extrapolated - LookingForward::extreme_layers_window_size / 2, 0);

  const int central_window_l0_size =
    min(central_window_l0_begin + LookingForward::extreme_layers_window_size, l0_size) - central_window_l0_begin;
  const int central_window_l1_size =
    min(central_window_l1_begin + LookingForward::middle_layer_window_size, l1_size) - central_window_l1_begin;
  const int central_window_l2_size =
    min(central_window_l2_begin + LookingForward::extreme_layers_window_size, l2_size) - central_window_l2_begin;

  const auto inverse_dz2 = 1.f / (z0 - z2);

  const auto qop_range =
    fabsf(qop) > LookingForward::linear_range_qop_end ? 1.f : fabsf(qop) * (1.f / LookingForward::linear_range_qop_end);
  const auto opening_x_at_z_magnet_diff =
    LookingForward::x_at_magnet_range_0 +
    qop_range * (LookingForward::x_at_magnet_range_1 - LookingForward::x_at_magnet_range_0);

  const auto do_sign_check = fabsf(qop) > (1.f / LookingForward::sign_check_momentum_threshold);

  // Due to shared_x1
  __syncthreads();

  for (int i = threadIdx.x; i < central_window_l1_size; i += blockDim.x) {
    shared_x1[i] = scifi_hits_x0[l1_start + central_window_l1_begin + i];
  }

  // Due to shared_x1
  __syncthreads();

  constexpr int blockdim_x = 32;
  for (uint tid_x = threadIdx.x; tid_x < blockdim_x; tid_x += blockDim.x) {
    uint16_t number_of_found_triplets = 0;

    // Treat central window iteration
    for (int i = tid_x; i < central_window_l0_size * central_window_l2_size; i += blockdim_x) {
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
        int best_h1_rel = -1;

        for (int h1_rel = local_central_window_l1_begin; h1_rel < local_central_window_l1_end; ++h1_rel) {
          const auto expected_x1 = precalc_expected_x1 + z1 * slope_t1_t3;
          const auto x1 = shared_x1[h1_rel];
          const auto chi2 = (expected_x1 - x1) * (expected_x1 - x1);

          if (chi2 < best_chi2) {
            best_chi2 = chi2;
            best_h1_rel = h1_rel;
          }
        }

        if (best_h1_rel != -1) {
          // if (Configuration::verbosity_level >= logger::debug) {
          //   printf("Best triplet found: %i, %i, %i, %f\n", h0_rel, h2_rel, best_j, best_chi2);
          // }

          // Encode j into chi2
          int* best_chi2_int = reinterpret_cast<int*>(&best_chi2);
          best_chi2_int[0] = (best_chi2_int[0] & 0xFFFFFFE0) + best_h1_rel;

          // Store chi2 with encoded j
          scifi_lf_triplet_best[h0_rel * LookingForward::extreme_layers_window_size + h2_rel] = best_chi2;

          // Store in per-thread storage the found hits
          scifi_lf_found_triplets[tid_x * (LookingForward::maximum_number_of_triplets_per_seed / blockdim_x) + number_of_found_triplets++] =
            static_cast<int16_t>(triplet_seed * LookingForward::maximum_number_of_triplets_per_seed + h0_rel * LookingForward::extreme_layers_window_size + h2_rel);
        }

        // if (best_h1_rel != -1) {
        //   // if (Configuration::verbosity_level >= logger::info) {
        //   //   printf("Best triplet found: %i, %i, %i, %f\n", h0_rel, h2_rel, best_h1_rel, best_chi2);
        //   // }

        //   const int current_insert_index = atomicAdd(atomics_scifi, 1);

        //   if (current_insert_index >= LookingForward::maximum_number_of_candidates_per_ut_track) {
        //     printf("Over limit (%i)\n", current_insert_index);
        //   }

        //   scifi_tracks[current_insert_index] = SciFi::TrackHits {
        //                         static_cast<uint16_t>(l0_start + central_window_l0_begin + h0_rel),
        //                         static_cast<uint16_t>(l1_start + central_window_l1_begin + best_h1_rel),
        //                         static_cast<uint16_t>(l2_start + central_window_l2_begin + h2_rel),
        //                         static_cast<uint16_t>(layer_0),
        //                         static_cast<uint16_t>(layer_1),
        //                         static_cast<uint16_t>(layer_2),
        //                         0.f,
        //                         updated_qop,
        //                         static_cast<uint16_t>(ut_track_number)};
        // }
      }
    }

    // Store number of found triplets by this thread
    scifi_lf_number_of_found_triplets[tid_x] = number_of_found_triplets;
  }
}
