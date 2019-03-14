#include "LFInitialTripletSeedingImpl.cuh"
#include "BinarySearchTools.cuh"

__device__ void lf_initial_triplet_seeding_impl(
  const SciFi::Hits& scifi_hits,
  const uint8_t h0_candidate_size,
  const uint8_t h1_candidate_size,
  const uint8_t h2_candidate_size,
  const uint8_t relative_middle_layer,
  const float max_chi2,
  float* best_chi2,
  int8_t* best_h0_h2,
  const short* scifi_lf_candidates,
  const float z0,
  const float z1,
  const float z2,
  const float qop,
  const int event_offset)
{
  // Tile size is 16
  constexpr int tile_size = 16;
  constexpr int tile_size_mask = 0xF;
  constexpr int tile_size_shift_div = 4;

  __shared__ float shared_partial_chi2[tile_size * tile_size];

  // Required constants for the chi2 calculation below
  const auto dz1 = (z1 - z0);
  const auto dz2 = (z2 - z0);
  float extrap1 = LookingForward::forward_param * qop * dz1 * dz1;
  extrap1 *= extrap1;
  const float zdiff = dz2 / dz1;
  const float extrap2 = LookingForward::forward_param * qop * dz2 * dz2;

  // Search best triplet
  // Tiled processing of h0 and h2
  for (int8_t i = 0; i < (h0_candidate_size + tile_size + 1) >> tile_size_shift_div; ++i) {
    // Note: Part of wmma can be allocated here

    for (int8_t j = 0; j < (h2_candidate_size + tile_size + 1) >> tile_size_shift_div; ++j) {
      // Note: The other part of wmma can be allocated here

      __syncthreads();

      // Note: This block of code is doable by wmma
      for (int16_t k = threadIdx.x; k < tile_size * tile_size; k += blockDim.x) {
        const int8_t h0_rel = i * tile_size + (k % tile_size);
        const int8_t h2_rel = j * tile_size + (k / tile_size);

        auto partial_chi2 = 1000.f * max_chi2;
        if (h0_rel < h0_candidate_size && h2_rel < h2_candidate_size) {
          const auto x0 = scifi_hits.x0[event_offset +
            scifi_lf_candidates[(relative_middle_layer - 1) * LookingForward::maximum_number_of_candidates + h0_rel]];
          const auto x2 = scifi_hits.x0[event_offset +
            scifi_lf_candidates[(relative_middle_layer + 1) * LookingForward::maximum_number_of_candidates + h2_rel]];
          partial_chi2 = x2 - x0 + x0 * zdiff - extrap2;
          // Note: To get the chi2 from the partial_chi2:
          // extrap1 + (partial_chi2 - x1 * zdiff) * (partial_chi2 - x1 * zdiff)
        }
        shared_partial_chi2[k] = partial_chi2;
      }

      __syncthreads();

      // Iterate over all h1s
      // Find best chi2, h0 and h2 using the partial chi2 from before
      for (int16_t h1_rel = threadIdx.x; h1_rel < h1_candidate_size; h1_rel += blockDim.x) {
        const float x1_zdiff = scifi_hits.x0[event_offset +
          scifi_lf_candidates[relative_middle_layer * LookingForward::maximum_number_of_candidates + h1_rel]] 
          * zdiff;

        float local_best_chi2 = max_chi2;
        int16_t local_best_k = -1;

        for (int16_t k = 0; k < tile_size * tile_size; ++k) {
          float chi2 = shared_partial_chi2[k] - x1_zdiff;
          chi2 = extrap1 + chi2 * chi2;

          if (chi2 < local_best_chi2) {
            local_best_chi2 = chi2;
            local_best_k = k;
          }
        }

        if (local_best_k != -1 && local_best_chi2 < best_chi2[h1_rel]) {
          best_chi2[h1_rel] = local_best_chi2;
          best_h0_h2[h1_rel] = i * tile_size + (local_best_k & tile_size_mask);
          best_h0_h2[LookingForward::maximum_number_of_candidates + h1_rel] = j * tile_size + (local_best_k >> tile_size_shift_div);
        }
      }
    }
  }
}
