#include "LFTripletSeedingImpl.cuh"
#include "BinarySearchTools.cuh"

__device__ void lf_triplet_seeding_impl(
  const SciFi::Hits& scifi_hits,
  const uint8_t h0_candidate_size,
  const uint8_t h1_candidate_size,
  const uint8_t h2_candidate_size,
  const uint8_t relative_middle_layer,
  const short* dev_scifi_lf_candidates,
  const float max_chi2,
  float* best_chi2,
  int8_t* best_h0_h2,
  const uint event_offset,
  const float z0,
  const float z1,
  const float z2,
  const float qop)
{
  // Tile size is 16
  constexpr int tile_size = 16;
  __shared__ float shared_chi2[tile_size * tile_size];
  __shared__ uint8_t shared_index[tile_size * tile_size];

  // Required constants for the chi2 calculation below
  const auto dz1 = (z1 - z0);
  const auto dz2 = (z2 - z0);
  const auto zdiff_inv = 1.f / dz1;
  auto extrap1 = LookingForward::forward_param * qop * dz1 * dz1;
  extrap1 *= extrap1;
  const auto extrap2 = LookingForward::forward_param * qop * dz2 * dz2;

  // Search best triplet
  for (int8_t i = 0; i < (h0_candidate_size + tile_size + 1) / tile_size; ++i) {
    for (int8_t j = 0; j < (h2_candidate_size + tile_size + 1) / tile_size; ++j) {

      // Note: wmma can be allocated here

      // Iterate over all h1s
      // for (int8_t h1_rel = 0; h1_rel < h1_candidate_size; ++h1_rel) {
      for (int8_t h1_rel = 0; h1_rel < h1_candidate_size; ++h1_rel) {
        const auto h1_rel_index = dev_scifi_lf_candidates[
          relative_middle_layer * LookingForward::maximum_number_of_candidates + h1_rel];
        const auto x1 = scifi_hits.x0[event_offset + h1_rel_index];

        // Note: wmma addition can be allocated here

        // Initialize shared_chi2
        __syncthreads();
        for (uint16_t k = threadIdx.x; k < tile_size * tile_size; k += blockDim.x) {
          shared_chi2[k] = max_chi2;
          shared_index[k] = k;
        }
        __syncthreads();

        // for (int k=0; k<tile_size * tile_size; ++k) {
        //   if ((k % tile_size) == 0) {
        //     printf("\n");
        //   }
        //   printf("%f ", shared_chi2[k]);
        // }
        // printf("\n");

        // Note: This block of code is doable by wmma
        for (int16_t k = threadIdx.x; k < tile_size * tile_size; k+=blockDim.x) {
          const int8_t h0_rel = i * tile_size + (k % tile_size);
          const int8_t h2_rel = j * tile_size + (k / tile_size);
          if (h0_rel < h0_candidate_size && h2_rel < h2_candidate_size) {
            const auto h0_rel_index = dev_scifi_lf_candidates[
              (relative_middle_layer - 1) * LookingForward::maximum_number_of_candidates + h0_rel];
            const auto x0 = scifi_hits.x0[event_offset + h0_rel_index];
            
            const auto h2_rel_index = dev_scifi_lf_candidates[
              (relative_middle_layer + 1) * LookingForward::maximum_number_of_candidates + h2_rel];
            const auto x2 = scifi_hits.x0[event_offset + h2_rel_index];
            
            const auto tx = x1 * zdiff_inv - x0 * zdiff_inv;
            const auto expected_x2 = x0 + tx * dz2 + extrap2;
            const auto chi2 = extrap1 + (x2 - expected_x2) * (x2 - expected_x2);
            shared_chi2[k] = chi2;
          }
        }

        __syncthreads();

        // float local_best_chi2 = 100000000.f;
        // int local_best_index = 0;
        // for (int k=0; k<tile_size*tile_size; ++k) {
        //   if (shared_chi2[k] < local_best_chi2) {
        //     local_best_chi2 = shared_chi2[k];
        //     local_best_index = k;
        //   }
        // }
        // printf("Best index, chi2: %i, %f\n", local_best_index, local_best_chi2);

        // for (int k=0; k<tile_size * tile_size; ++k) {
        //   if ((k % tile_size) == 0) {
        //     printf("\n");
        //   }
        //   printf("%f ", shared_chi2[k]);
        // }
        // printf("\n");

        // shared_chi2 contains all calculated chi2s
        // Use a reduction to fetch the best one
        // int16_t to be on the safe side
        for (int16_t s = 1; s < tile_size * tile_size; s *= 2) {
          for (int16_t r = 2 * threadIdx.x; r < tile_size * tile_size; r += 2 * blockDim.x) {
            if (r % (2 * s) == 0 && shared_chi2[r + s] < shared_chi2[r]) {
              shared_chi2[r] = shared_chi2[r + s];
              shared_index[r] = shared_index[r + s];
            }
          }
          __syncthreads();
        }

        // for (int k=0; k<tile_size * tile_size; ++k) {
        //   if ((k % tile_size) == 0) {
        //     printf("\n");
        //   }
        //   printf("%f ", shared_chi2[k]);
        // }
        // printf("\n");

        // printf("Found best index, chi2: %i, %f\n", shared_index[0], shared_chi2[0]);

        // Note: We could keep in a buffer the best shared_chi2 found (shared_chi2[0]) and
        //       the best h0h2 found (shared_index[0]), and do the following check simultaneously
        //       for all h1s
        //
        // Now shared_chi2 and shared_index contain the best chi2 and best index, respectively
        // Compare that to the currently stored and save it if's better
        if (threadIdx.x == 0 && shared_chi2[0] < best_chi2[h1_rel]) {
          best_chi2[h1_rel] = shared_chi2[0];
          best_h0_h2[h1_rel] = i * tile_size + (shared_index[0] % 16);
          best_h0_h2[64 + h1_rel] = j * tile_size + (shared_index[0] >> 4);
        }

        __syncthreads();
      }
    }
  }
}
