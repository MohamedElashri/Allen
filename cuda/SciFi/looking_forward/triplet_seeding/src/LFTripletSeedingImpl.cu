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
  const uint number_of_seeds)
{
  std::vector<SciFi::CombinedValue> best_combined(l1_size);
  std::vector<int> best_combined_keys(l1_size);
  for (int i = 0; i < l1_size; ++i) {
    best_combined_keys[i] = i;
  }

  // printf("Event %i, track %i\nSizes {%i, %i, %i}\n", blockIdx.x, number_of_ut_track, l0_size, l1_size, l2_size);

  // Required constants for the chi2 calculation below
  float extrap1 = LookingForward::get_extrap(qop, z1 - z0);
  extrap1 *= extrap1;
  const float zdiff = (z2 - z0) / (z1 - z0);
  const float extrap2 = LookingForward::get_extrap(qop, (z2 - z0));

  // Search best triplets per h1
  // Tiled processing of h0 and h2
  for (int i = 0; i < (l0_size + LookingForward::tile_size - 1) / LookingForward::tile_size; ++i) {
    for (int j = 0; j < (l2_size + LookingForward::tile_size - 1) / LookingForward::tile_size; ++j) {
      __syncthreads();

      // Search best triplets per h1
      for (uint k = threadIdx.x; k < LookingForward::tile_size * LookingForward::tile_size; k += blockDim.x) {
        const uint h0_rel = i * LookingForward::tile_size + (k % LookingForward::tile_size);
        const uint h2_rel = j * LookingForward::tile_size + (k / LookingForward::tile_size);

        auto partial_chi2 = 10000.f * LookingForward::chi2_max_triplet_single;
        if (h0_rel < l0_size && h2_rel < l2_size) {
          const auto x0 = scifi_hits_x0[l0_start + h0_rel];
          const auto x2 = scifi_hits_x0[l2_start + h2_rel];
          partial_chi2 = x2 - x0 + x0 * zdiff - extrap2;
        }
        shared_partial_chi2[k] = partial_chi2;
      }

      __syncthreads();

      // Iterate over all h1s
      // Find best chi2, h0 and h2 using the partial chi2 from before
      for (uint h1_rel = threadIdx.x; h1_rel < l1_size; h1_rel += blockDim.x) {
        const float x1_zdiff = scifi_hits_x0[l1_start + h1_rel] * zdiff;

        float best_chi2 = LookingForward::chi2_max_triplet_single;
        int best_k = -1;

        for (int k = 0; k < LookingForward::tile_size * LookingForward::tile_size; ++k) {
          float chi2 = shared_partial_chi2[k] - x1_zdiff;
          chi2 = extrap1 + chi2 * chi2;

          if (chi2 < best_chi2) {
            best_chi2 = chi2;
            best_k = k;
          }
        }

        if (best_k != -1 && best_chi2 < best_combined[h1_rel].chi2) {
          best_combined[h1_rel] =
            SciFi::CombinedValue {best_chi2,
                                  (int16_t)(i * LookingForward::tile_size + (best_k % LookingForward::tile_size)),
                                  (int16_t)(j * LookingForward::tile_size + (best_k / LookingForward::tile_size))};
        }
      }
    }
  }

  // for (uint i = 0; i < l1_size; ++i) {
  //   const auto best_combo = best_combined[i];
  //   printf(" %i, %i, %f\n", best_combo.h0, best_combo.h2, best_combo.chi2);
  // }

  std::sort(best_combined_keys.begin(), best_combined_keys.end(), [&](const int a, const int b) {
    return best_combined[a].chi2 < best_combined[b].chi2;
  });

  // Note: LookingForward::maximum_number_of_candidates_per_ut_track / 2 due to (0, 2, 4) and (1, 3, 5) being looked
  //       at separately.
  for (int i = 0; i < (LookingForward::maximum_number_of_candidates_per_ut_track / number_of_seeds) && i < l1_size;
       ++i) {
    const auto best_h1 = best_combined_keys[i];
    const auto best_combo = best_combined[best_h1];

    if (best_combo.h0 != -1) {
      const auto h0 = l0_start + best_combo.h0;
      const auto h1 = l1_start + best_h1;
      const auto h2 = l2_start + best_combo.h2;

      // printf(" %i, %i, %i, %f\n", h0, h1, h2, best_combo.chi2);

      const int insert_index = atomicAdd(atomics_scifi, 1);
      scifi_tracks[insert_index] = SciFi::TrackHits {
        h0,
        h1,
        h2,
        (uint16_t) layer_0,
        (uint16_t) layer_1,
        (uint16_t) layer_2,
        best_combo.chi2,
        LookingForward::qop_update_multi_par(
          *ut_state, scifi_hits_x0[h0], z0, scifi_hits_x0[h1], z1, layer_1, dev_looking_forward_constants),
        number_of_ut_track};
    }
  }
}
