#include "LFTripletSeedingImpl.cuh"
#include "BinarySearchTools.cuh"
#include <mma.h>
#include "LookingForwardTools.cuh"

__device__ void lf_triplet_seeding_choose_best_triplets_for_h1(
  const float* scifi_hits_x0,
  const short* scifi_lf_candidates,
  const uint8_t layer_0,
  const uint8_t layer_1,
  const uint8_t layer_2,
  const float zdiff,
  const float* shared_partial_chi2,
  const float extrap1,
  const int h1_candidate_size,
  const int8_t h0_tile_index,
  const int8_t h2_tile_index,
  const float max_chi2,
  const LookingForward::Constants* dev_looking_forward_constants,
  const int16_t max_n_h1s_this_thread,
  float* best_chi2_h1s_this_thread,
  int8_t* best_h0_h2_h1s_this_thread)
{

  // Iterate over all h1s
  // Find best chi2, h0 and h2 using the partial chi2 from before
  for (int16_t h1_rel = threadIdx.x; h1_rel < h1_candidate_size; h1_rel += blockDim.x) {
    const float x1_zdiff =
      scifi_hits_x0
      [scifi_lf_candidates[layer_1 * LookingForward::maximum_number_of_candidates + h1_rel]] *
      zdiff;

    const int16_t h1_thread = h1_rel / LookingForward::n_threads_triplet_seeding;
    for (int16_t k = 0; k < LookingForward::tile_size * LookingForward::tile_size; ++k) {
      float chi2 = shared_partial_chi2[k] - x1_zdiff;
      chi2 = extrap1 + chi2 * chi2;
      // check whether chi2 is better than worst saved so far for this h1
      int16_t pos = h1_thread*LookingForward::maximum_number_of_triplets_per_h1 + LookingForward::maximum_number_of_triplets_per_h1 - 1;
      if (chi2 < best_chi2_h1s_this_thread[pos]) {
        // dertermine which position the chi2 corresponds to
        for (int16_t i = 0; i < LookingForward::maximum_number_of_triplets_per_h1 - 1; ++i) {
          if (chi2 < best_chi2_h1s_this_thread[pos-1]) {
            pos--;
          } else break;
        }
        // move worse chi2s in array back by one position
        for (int16_t i = LookingForward::maximum_number_of_triplets_per_h1 - 2; i >= pos; --i) {
          best_chi2_h1s_this_thread[i + 1] = best_chi2_h1s_this_thread[i];
          best_h0_h2_h1s_this_thread[i + 1] = best_h0_h2_h1s_this_thread[i];
          best_h0_h2_h1s_this_thread[max_n_h1s_this_thread * LookingForward::maximum_number_of_triplets_per_h1 + i + 1] = best_h0_h2_h1s_this_thread[max_n_h1s_this_thread * LookingForward::maximum_number_of_triplets_per_h1 + i];
        }
        // add new chi2 value
        best_chi2_h1s_this_thread[pos] = chi2;
#if __CUDA_ARCH__ >= 700
        best_h0_h2_h1s_this_thread[pos] =
          h0_tile_index * LookingForward::tile_size + (k >> LookingForward::tile_size_shift_div);
        best_h0_h2_h1s_this_thread[max_n_h1s_this_thread * LookingForward::maximum_number_of_triplets_per_h1 + pos] =
          h2_tile_index * LookingForward::tile_size + (k & LookingForward::tile_size_mask);
#else
        best_h0_h2_h1s_this_thread[pos] =
          h0_tile_index * LookingForward::tile_size + (k & LookingForward::tile_size_mask);
        best_h0_h2_h1s_this_thread[max_n_h1s_this_thread * LookingForward::maximum_number_of_triplets_per_h1 + pos] =
          h2_tile_index * LookingForward::tile_size + (k >> LookingForward::tile_size_shift_div);
#endif
      }
    }
  }

}

__device__ void lf_triplet_seeding_impl(
  const float* scifi_hits_x0,
  const uint8_t h0_candidate_size,
  const uint8_t h1_candidate_size,
  const uint8_t h2_candidate_size,
  const uint8_t layer_0,
  const uint8_t layer_1,
  const uint8_t layer_2,
  const float max_chi2,
  const LookingForward::Constants* dev_looking_forward_constants,
  float* best_chi2,
  int8_t* best_h0_h2,
  const short* scifi_lf_candidates,
  const float dz1,
  const float dz2,
  const float qop)
{
  __shared__ float shared_partial_chi2[LookingForward::tile_size * LookingForward::tile_size];

  // Storage for best chi2 from triplets of one h1 candidate
  // this allows comparisons beyond the scope of the tiles in which the h0-h1-h2 combinations are treated
  // const int16_t max_n_h1s_this_thread = LookingForward::maximum_number_of_candidates / LookingForward::n_threads_triplet_seeding + (LookingForward::maximum_number_of_candidates % LookingForward::n_threads_triplet_seeding != 0);
  // float best_chi2_h1s_this_thread[max_n_h1s_this_thread * LookingForward::maximum_number_of_triplets_per_h1];
  // int8_t best_h0_h2_h1s_this_thread[max_n_h1s_this_thread * LookingForward::maximum_number_of_triplets_per_h1 * 2];
  // for (int16_t i = 0; i < max_n_h1s_this_thread * LookingForward::maximum_number_of_triplets_per_h1; ++i) {
  //   best_chi2_h1s_this_thread[i] = max_chi2;
  // }

  // Required constants for the chi2 calculation below
  float extrap1 = LookingForward::get_extrap1(qop, dz1);
  extrap1 *= extrap1;
  const float zdiff = dz2 / dz1;
  const float extrap2 = LookingForward::get_extrap2(qop, dz2);

// Tensor core specialization
#if __CUDA_ARCH__ >= 700

  const half zdiff_half = ((half) zdiff);
  const half big_max_chi2 = 1000.f * max_chi2;

  // Tensor core magic
  half* shared_wmma_a = (half*) shared_partial_chi2;
  half* shared_wmma_b = (half*) (shared_partial_chi2 + ((LookingForward::tile_size * LookingForward::tile_size) >> 1));

  // __shared__ half shared_wmma_a[LookingForward::tile_size * LookingForward::tile_size];
  // __shared__ half shared_wmma_b[LookingForward::tile_size * LookingForward::tile_size];
  nvcuda::wmma::fragment<nvcuda::wmma::matrix_a, LookingForward::tile_size, LookingForward::tile_size, LookingForward::tile_size, half, nvcuda::wmma::col_major> a_frag;
  nvcuda::wmma::fragment<nvcuda::wmma::matrix_b, LookingForward::tile_size, LookingForward::tile_size, LookingForward::tile_size, half, nvcuda::wmma::row_major> b_frag;
  nvcuda::wmma::fragment<nvcuda::wmma::accumulator, LookingForward::tile_size, LookingForward::tile_size, LookingForward::tile_size, float> c_frag;
  nvcuda::wmma::fragment<nvcuda::wmma::accumulator, LookingForward::tile_size, LookingForward::tile_size, LookingForward::tile_size, float> d_frag;
  nvcuda::wmma::fill_fragment(c_frag, -extrap2);

  // Search best triplets per h1

  // Tiled processing of h0 and h2
  for (int8_t i = 0; i<(h0_candidate_size + LookingForward::tile_size - 1)>> LookingForward::tile_size_shift_div; ++i) {
    for (int8_t j = 0; j<(h2_candidate_size + LookingForward::tile_size - 1)>> LookingForward::tile_size_shift_div; ++j) {
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
          shared_wmma_a[LookingForward::tile_size + k] = big_max_chi2;
          shared_wmma_a[2 * LookingForward::tile_size + k] = big_max_chi2;
        }
      }
      // TODO: Needed?
      __syncthreads();
      nvcuda::wmma::load_matrix_sync(a_frag, shared_wmma_a, LookingForward::tile_size);

      for (int16_t k = threadIdx.x; k < LookingForward::tile_size; k += blockDim.x) {
        const int8_t h2_rel = j * LookingForward::tile_size + k;
        if (h2_rel < h2_candidate_size) {
          shared_wmma_b[k] = scifi_hits_x0
            [scifi_lf_candidates[layer_2 * LookingForward::maximum_number_of_candidates + h2_rel]];
        }
        else {
          shared_wmma_b[k] = big_max_chi2;
        }
      }
      // TODO: Needed?
      __syncthreads();
      nvcuda::wmma::load_matrix_sync(b_frag, shared_wmma_b, LookingForward::tile_size);

      // Magic :)
      nvcuda::wmma::mma_sync(d_frag, a_frag, b_frag, c_frag);
      nvcuda::wmma::store_matrix_sync(shared_partial_chi2, d_frag, LookingForward::tile_size, nvcuda::wmma::mem_row_major);

      // Iterate over all h1s
      // Find best chi2, h0 and h2 using the partial chi2 from before
      for (int16_t h1_rel = threadIdx.x; h1_rel < h1_candidate_size; h1_rel += blockDim.x) {
        const float x1_zdiff =
          scifi_hits_x0
            [scifi_lf_candidates[layer_1 * LookingForward::maximum_number_of_candidates + h1_rel]] *
          zdiff;

        float local_best_chi2 = max_chi2;
        int16_t local_best_k = -1;

        for (int16_t k = 0; k < LookingForward::tile_size * LookingForward::tile_size; ++k) {
          float chi2 = shared_partial_chi2[k] - x1_zdiff;
          chi2 = extrap1 + chi2 * chi2;

          if (chi2 < local_best_chi2) {
            local_best_chi2 = chi2;
            local_best_k = k;
          }
        }

        if (local_best_k != -1 && local_best_chi2 < best_chi2[h1_rel]) {
          best_chi2[h1_rel] = local_best_chi2;
          best_h0_h2[h1_rel] = i * LookingForward::tile_size + (local_best_k >> LookingForward::tile_size_shift_div);
          best_h0_h2[LookingForward::maximum_number_of_candidates + h1_rel] =
            j * LookingForward::tile_size + (local_best_k & LookingForward::tile_size_mask);
        }
      }

      // lf_triplet_seeding_choose_best_triplets_for_h1(
    //     scifi_hits_x0,
    //     scifi_lf_candidates,
    //     triplet_seed,
    //     zdiff,
    //     shared_partial_chi2,
    //     extrap1,
    //     h1_candidate_size,
    //     i,
    //     j,
    //     max_chi2,
    //     dev_looking_forward_constants,
    //     max_n_h1s_this_thread,
    //     best_chi2_h1s_this_thread,
    //     best_h0_h2_h1s_this_thread);

    }
  }

#else

  // Search best triplets per h1

  // Tiled processing of h0 and h2
  for (int8_t i = 0; i<(h0_candidate_size + LookingForward::tile_size - 1)>> LookingForward::tile_size_shift_div; ++i) {
    for (int8_t j = 0; j<(h2_candidate_size + LookingForward::tile_size - 1)>> LookingForward::tile_size_shift_div; ++j) {

      __syncthreads();

      for (int16_t k = threadIdx.x; k < LookingForward::tile_size * LookingForward::tile_size; k += blockDim.x) {
        const int8_t h0_rel = i * LookingForward::tile_size + (k & LookingForward::tile_size_mask);
        const int8_t h2_rel = j * LookingForward::tile_size + (k >> LookingForward::tile_size_shift_div);

        float partial_chi2 = 1000.f * max_chi2;
        if (h0_rel < h0_candidate_size && h2_rel < h2_candidate_size) {
          const auto x0 =
            scifi_hits_x0[scifi_lf_candidates[layer_0 * LookingForward::maximum_number_of_candidates + h0_rel]];
          const auto x2 = scifi_hits_x0
            [scifi_lf_candidates[layer_2 * LookingForward::maximum_number_of_candidates + h2_rel]];
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
        const float x1_zdiff =
          scifi_hits_x0
            [scifi_lf_candidates[layer_1 * LookingForward::maximum_number_of_candidates + h1_rel]] *
          zdiff;

        float local_best_chi2 = max_chi2;
        int16_t local_best_k = -1;

        for (int16_t k = 0; k < LookingForward::tile_size * LookingForward::tile_size; ++k) {
          float chi2 = shared_partial_chi2[k] - x1_zdiff;
          chi2 = extrap1 + chi2 * chi2;

          if (chi2 < local_best_chi2) {
            local_best_chi2 = chi2;
            local_best_k = k;
          }
        }

        if (local_best_k != -1 && local_best_chi2 < best_chi2[h1_rel]) {
          best_chi2[h1_rel] = local_best_chi2;
          best_h0_h2[h1_rel] = i * LookingForward::tile_size + (local_best_k & LookingForward::tile_size_mask);
          best_h0_h2[LookingForward::maximum_number_of_candidates + h1_rel] =
            j * LookingForward::tile_size + (local_best_k >> LookingForward::tile_size_shift_div);
        }
      }

       // lf_triplet_seeding_choose_best_triplets_for_h1(
       //  scifi_hits_x0,
       //  scifi_lf_candidates,
       //  triplet_seed,
       //  zdiff,
       //  shared_partial_chi2,
       //  extrap1,
       //  h1_candidate_size,
       //  i,
       //  j,
       //  max_chi2,
       //  dev_looking_forward_constants,
       //  max_n_h1s_this_thread,
       //  best_chi2_h1s_this_thread,
       //  best_h0_h2_h1s_this_thread);
    }
  }
#endif

  // __syncthreads();

  // // Write best chosen triplets per h1 candidate to global memory
  // for (int16_t h1_rel = threadIdx.x; h1_rel < h1_candidate_size; h1_rel += blockDim.x) {
  //   for (int16_t h1_triplet = 0; h1_triplet < LookingForward::maximum_number_of_triplets_per_h1; ++h1_triplet) {
  //     const int16_t h1_thread = h1_rel / LookingForward::n_threads_triplet_seeding;
  //     const int16_t pos = h1_thread*LookingForward::maximum_number_of_triplets_per_h1 + h1_triplet;

  //     if (best_chi2_h1s_this_thread[pos] < max_chi2) {
  //       best_chi2[h1_rel * LookingForward::maximum_number_of_triplets_per_h1 + h1_triplet] = best_chi2_h1s_this_thread[pos];
  //       best_h0_h2[h1_rel * LookingForward::maximum_number_of_triplets_per_h1 + h1_triplet] = best_h0_h2_h1s_this_thread[pos];
  //       best_h0_h2[LookingForward::maximum_number_of_candidates * LookingForward::maximum_number_of_triplets_per_h1 + h1_rel * LookingForward::maximum_number_of_triplets_per_h1 + h1_triplet] = best_h0_h2_h1s_this_thread[max_n_h1s_this_thread * LookingForward::maximum_number_of_triplets_per_h1 + pos];
  //     }
  //   }
  // }

}
