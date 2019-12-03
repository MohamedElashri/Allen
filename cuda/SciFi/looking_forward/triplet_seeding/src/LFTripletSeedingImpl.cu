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
  const uint ut_total_number_of_tracks,
  const float qop,
  const float ut_tx,
  const float velo_tx,
  const float x_at_z_magnet,
  float* shared_x1,
  int* scifi_lf_found_triplets,
  int8_t* scifi_lf_number_of_found_triplets,
  const uint triplet_seed)
{
  const int l0_start = initial_windows[layer_0 * LookingForward::number_of_elements_initial_window * ut_total_number_of_tracks];
  const int l1_start = initial_windows[layer_1 * LookingForward::number_of_elements_initial_window * ut_total_number_of_tracks];
  const int l2_start = initial_windows[layer_2 * LookingForward::number_of_elements_initial_window * ut_total_number_of_tracks];

  const auto inverse_dz2 = 1.f / (z0 - z2);
  const auto constant_expected_x1 =
    (triplet_seed == 0 ? LookingForward::sagitta_alignment_x1_triplet0 : LookingForward::sagitta_alignment_x1_triplet1);

  const auto qop_range =
    fabsf(qop) > LookingForward::linear_range_qop_end ? 1.f : fabsf(qop) * (1.f / LookingForward::linear_range_qop_end);
  const auto opening_x_at_z_magnet_diff =
    LookingForward::x_at_magnet_range_0 +
    qop_range * (LookingForward::x_at_magnet_range_1 - LookingForward::x_at_magnet_range_0);

  const auto do_slope_sign_check = fabsf(qop) > (1.f / LookingForward::sign_check_momentum_threshold);

  // Due to shared_x1
  __syncthreads();

  for (int i = threadIdx.x; i < l1_size; i += blockDim.x) {
    shared_x1[i] = scifi_hits_x0[l1_start + i];
  }

  // Due to shared_x1
  __syncthreads();

  for (uint tid_x = threadIdx.x; tid_x < LookingForward::triplet_seeding_block_dim_x; tid_x += blockDim.x) {
    uint16_t number_of_found_triplets = 0;

    // Treat central window iteration
    for (int i = tid_x; i < l0_size * l2_size; i += LookingForward::triplet_seeding_block_dim_x) {
      const auto h0_rel = i % l0_size;
      const auto h2_rel = i / l0_size;

      const auto x0 = scifi_hits_x0[l0_start + h0_rel];
      const auto x2 = scifi_hits_x0[l2_start + h2_rel];

      // // Extrapolation
      const auto slope_t1_t3 = (x0 - x2) * inverse_dz2;
      const auto expected_x1 = z1 * slope_t1_t3 + (x0 - slope_t1_t3 * z0) * constant_expected_x1;

      const auto track_x_at_z_magnet = x0 + (LookingForward::z_magnet - z0) * slope_t1_t3;
      const auto x_at_z_magnet_diff = fabsf(
        track_x_at_z_magnet - x_at_z_magnet -
        (LookingForward::x_at_z_p0 + LookingForward::x_at_z_p1 * slope_t1_t3 +
         LookingForward::x_at_z_p2 * slope_t1_t3 * slope_t1_t3 +
         LookingForward::x_at_z_p3 * slope_t1_t3 * slope_t1_t3 * slope_t1_t3));

      const auto equal_signs_in_slopes = signbit(slope_t1_t3 - velo_tx) == signbit(ut_tx - velo_tx);
      const bool process_element =
        x_at_z_magnet_diff < opening_x_at_z_magnet_diff && (!do_slope_sign_check || equal_signs_in_slopes);

      if (process_element && number_of_found_triplets < LookingForward::maximum_number_of_triplets_per_thread) {
        // Binary search of candidate
        const auto candidate_index = binary_search_leftmost(shared_x1, l1_size, expected_x1);

        float best_chi2 = LookingForward::chi2_max_triplet_single;
        int best_h1_rel = -1;

        // It is now either candidate_index - 1 or candidate_index
        for (int h1_rel = candidate_index - 1; h1_rel < candidate_index + 1; ++h1_rel) {
          if (h1_rel >= 0 && h1_rel < l1_size) {
            const auto x1 = shared_x1[h1_rel];
            const auto chi2 = (x1 - expected_x1) * (x1 - expected_x1);

            if (chi2 < best_chi2) {
              best_chi2 = chi2;
              best_h1_rel = h1_rel;
            }
          }
        }

        if (best_h1_rel != -1) {
          // Store chi2, h0, h1 and h2 encoded in a 32-bit type
          // Bits (LSB):
          //  0-4: h2_rel
          //  5-9: h1_rel
          //  10-14: h0_rel
          //  15: triplet seed
          //  16-31: most significant bits of chi2
          int* best_chi2_int = reinterpret_cast<int*>(&best_chi2);
          int h0_h1_h2_rel = (triplet_seed << 15) | (h0_rel << 10) | (best_h1_rel << 5) | h2_rel;

          scifi_lf_found_triplets
            [tid_x * LookingForward::maximum_number_of_triplets_per_thread + number_of_found_triplets++] =
              (best_chi2_int[0] & 0xFFFF0000) + h0_h1_h2_rel;
        }
      }
    }

    // Store number of found triplets by this thread
    scifi_lf_number_of_found_triplets[tid_x] = number_of_found_triplets;
  }
}
