#include "LFTripletSeedingImpl.cuh"
#include "BinarySearchTools.cuh"
#include "LookingForwardTools.cuh"

__device__ void lf_triplet_seeding_impl(
  const float* scifi_hits_x0,
  const uint8_t h0_candidate_size,
  const uint8_t h1_candidate_size,
  const uint8_t h2_candidate_size,
  const uint8_t layer_0,
  const uint8_t layer_1,
  const uint8_t layer_2,
  SciFi::CombinedValue* best_combined,
  const short* scifi_lf_candidates,
  const float dz1,
  const float dz2,
  const float qop,
  float* shared_partial_chi2)
{
  // Required constants for the chi2 calculation below
  float extrap1 = LookingForward::get_extrap(qop, dz1);
  extrap1 *= extrap1;
  const float zdiff = dz2 / dz1;
  const float extrap2 = LookingForward::get_extrap(qop, dz2);

// Tensor core specialization
#if __CUDA_ARCH__ >= 700 && defined(TENSOR_CORES_ENABLED)
  const half zdiff_half = ((half) zdiff);

  // Tensor core magic
  half* shared_wmma_a = (half*) shared_partial_chi2;
  half* shared_wmma_b = (half*) (shared_partial_chi2 + ((LookingForward::tile_size * LookingForward::tile_size) >> 1));

  nvcuda::wmma::fragment<
    nvcuda::wmma::matrix_a,
    LookingForward::tile_size,
    LookingForward::tile_size,
    LookingForward::tile_size,
    half,
    nvcuda::wmma::col_major>
    a_frag;
  nvcuda::wmma::fragment<
    nvcuda::wmma::matrix_b,
    LookingForward::tile_size,
    LookingForward::tile_size,
    LookingForward::tile_size,
    half,
    nvcuda::wmma::row_major>
    b_frag;
  nvcuda::wmma::fragment<
    nvcuda::wmma::accumulator,
    LookingForward::tile_size,
    LookingForward::tile_size,
    LookingForward::tile_size,
    float>
    c_frag;
  nvcuda::wmma::fragment<
    nvcuda::wmma::accumulator,
    LookingForward::tile_size,
    LookingForward::tile_size,
    LookingForward::tile_size,
    float>
    d_frag;
  nvcuda::wmma::fill_fragment(c_frag, -extrap2);
#endif

  // Search best triplets per h1
  // Tiled processing of h0 and h2
  for (int8_t i = 0; i<(h0_candidate_size + LookingForward::tile_size - 1)>> LookingForward::tile_size_shift_div; ++i) {
    for (int8_t j = 0; j<(h2_candidate_size + LookingForward::tile_size - 1)>> LookingForward::tile_size_shift_div;
         ++j) {
      __syncthreads();

#if __CUDA_ARCH__ >= 700 && defined(TENSOR_CORES_ENABLED)
      // Initialize wmma shared memory arrays
      for (int16_t k = threadIdx.x; k < LookingForward::tile_size * LookingForward::tile_size; k += blockDim.x) {
        shared_partial_chi2[k] = 0;
      }

      for (int16_t k = threadIdx.x; k < LookingForward::tile_size; k += blockDim.x) {
        shared_wmma_a[k] = 1;
        shared_wmma_b[LookingForward::tile_size + k] = 1;
        shared_wmma_b[2 * LookingForward::tile_size + k] = zdiff_half;
      }

      for (int16_t k = threadIdx.x; k < LookingForward::tile_size; k += blockDim.x) {
        const int8_t h0_rel = i * LookingForward::tile_size + k;
        if (h0_rel < h0_candidate_size) {
          const half x0 =
            scifi_hits_x0[scifi_lf_candidates[layer_0 * LookingForward::maximum_number_of_candidates + h0_rel]];
          shared_wmma_a[LookingForward::tile_size + k] = -x0;
          shared_wmma_a[2 * LookingForward::tile_size + k] = x0;
        }
        else {
          shared_wmma_a[LookingForward::tile_size + k] = 10000.f * LookingForward::chi2_max_triplet_single;
          shared_wmma_a[2 * LookingForward::tile_size + k] = 10000.f * LookingForward::chi2_max_triplet_single;
        }
      }
      // TODO: Needed?
      __syncthreads();
      nvcuda::wmma::load_matrix_sync(a_frag, shared_wmma_a, LookingForward::tile_size);

      for (int16_t k = threadIdx.x; k < LookingForward::tile_size; k += blockDim.x) {
        const int8_t h2_rel = j * LookingForward::tile_size + k;
        if (h2_rel < h2_candidate_size) {
          shared_wmma_b[k] =
            scifi_hits_x0[scifi_lf_candidates[layer_2 * LookingForward::maximum_number_of_candidates + h2_rel]];
        }
        else {
          shared_wmma_b[k] = 10000.f * LookingForward::chi2_max_triplet_single;
        }
      }
      // TODO: Needed?
      __syncthreads();
      nvcuda::wmma::load_matrix_sync(b_frag, shared_wmma_b, LookingForward::tile_size);

      nvcuda::wmma::mma_sync(d_frag, a_frag, b_frag, c_frag);
      nvcuda::wmma::store_matrix_sync(
        shared_partial_chi2, d_frag, LookingForward::tile_size, nvcuda::wmma::mem_col_major);
#else
      // Search best triplets per h1
      for (int k = threadIdx.x; k < LookingForward::tile_size * LookingForward::tile_size; k += blockDim.x) {
        const int8_t h0_rel = i * LookingForward::tile_size + (k % LookingForward::tile_size);
        const int8_t h2_rel = j * LookingForward::tile_size + (k / LookingForward::tile_size);

        float partial_chi2 = 10000.f * LookingForward::chi2_max_triplet_single;
        if (h0_rel < h0_candidate_size && h2_rel < h2_candidate_size) {
          const auto x0 =
            scifi_hits_x0[scifi_lf_candidates[layer_0 * LookingForward::maximum_number_of_candidates + h0_rel]];
          const auto x2 =
            scifi_hits_x0[scifi_lf_candidates[layer_2 * LookingForward::maximum_number_of_candidates + h2_rel]];
          partial_chi2 = x2 - x0 + x0 * zdiff - extrap2;
        }
        shared_partial_chi2[k] = partial_chi2;
      }
      __syncthreads();
#endif

      // Iterate over all h1s
      // Find best chi2, h0 and h2 using the partial chi2 from before
      for (int h1_all_threads = threadIdx.x; h1_all_threads < LookingForward::maximum_number_of_triplets_per_h1 *
                                                                LookingForward::maximum_number_of_candidates;
           h1_all_threads += blockDim.x) {
        const auto h1_rel = h1_all_threads % LookingForward::maximum_number_of_candidates;

        if (h1_rel < h1_candidate_size) {
          const auto section = h1_all_threads / LookingForward::maximum_number_of_candidates;

          const float x1_zdiff =
            scifi_hits_x0[scifi_lf_candidates[layer_1 * LookingForward::maximum_number_of_candidates + h1_rel]] * zdiff;

          float best_chi2 = LookingForward::chi2_max_triplet_single;
          int best_k = -1;

          for (int k = 0 + section * LookingForward::tile_size * LookingForward::tile_size / 2;
               k < LookingForward::tile_size * LookingForward::tile_size / 2 +
                     section * LookingForward::tile_size * LookingForward::tile_size / 2;
               ++k) {

            float chi2 = shared_partial_chi2[k] - x1_zdiff;
            chi2 = extrap1 + chi2 * chi2;

            if (chi2 < best_chi2) {
              best_chi2 = chi2;
              best_k = k;
            }
          }

          if (
            best_k != -1 &&
            best_chi2 < best_combined[h1_rel + section * LookingForward::maximum_number_of_candidates].chi2) {
            best_combined[h1_rel + section * LookingForward::maximum_number_of_candidates] =
              SciFi::CombinedValue {best_chi2,
                                    (int16_t)(i * LookingForward::tile_size + (best_k % LookingForward::tile_size)),
                                    (int16_t)(j * LookingForward::tile_size + (best_k / LookingForward::tile_size))};
          }
        }
      }
    }
  }
}
