#include "SearchByTriplet.cuh"

/**
 * @brief Search for compatible triplets in
 *        three neighbouring modules on one side
 */
__device__ void track_seeding(
  Velo::ConstClusters& velo_cluster_container,
  const Velo::Module* module_data,
  const short* h0_candidates,
  const short* h2_candidates,
  bool* hit_used,
  Velo::TrackletHits* tracklets,
  uint* tracks_to_follow,
  unsigned short* h1_indices,
  uint* dev_atomics_velo)
{
  // Add to an array all non-used h1 hits with candidates
  for (uint h1_rel_index = threadIdx.x; h1_rel_index < module_data[0].hitNums; h1_rel_index += blockDim.x) {
    const auto h1_index = module_data[0].hitStart + h1_rel_index;
    const auto h0_size = h0_candidates[2 * h1_index + 1];
    const auto h2_size = h2_candidates[2 * h1_index + 1];
    if (!hit_used[h1_index] && h0_size > 0 && h2_size > 0) {
      const auto current_hit = atomicAdd(dev_atomics_velo + 3, 1);
      h1_indices[current_hit] = h1_index;
    }
  }

  // Also add other side, processing both sides simultaneously
  for (uint h1_rel_index = threadIdx.x; h1_rel_index < module_data[1].hitNums; h1_rel_index += blockDim.x) {
    const auto h1_index = module_data[1].hitStart + h1_rel_index;
    const auto h0_size = h0_candidates[2 * h1_index + 1];
    const auto h2_size = h2_candidates[2 * h1_index + 1];
    if (!hit_used[h1_index] && h0_size > 0 && h2_size > 0) {
      const auto current_hit = atomicAdd(dev_atomics_velo + 3, 1);
      h1_indices[current_hit] = h1_index;
    }
  }

  // Due to h1_indices
  __syncthreads();

  // Assign a h1 to each threadIdx.x
  const auto number_of_hits_h1 = dev_atomics_velo[3];
  for (uint h1_rel_index = threadIdx.x; h1_rel_index < number_of_hits_h1; h1_rel_index += blockDim.x) {
    // The output we are searching for
    unsigned short best_h0 = 0;
    unsigned short best_h2 = 0;
    unsigned short h1_index = 0;
    float best_fit = Configuration::velo_search_by_triplet::max_scatter_seeding;

    // Fetch h1
    h1_index = h1_indices[h1_rel_index];
    const Velo::HitBase h1 {velo_cluster_container.x(h1_index),
                            velo_cluster_container.y(h1_index),
                            velo_cluster_container.z(h1_index)};

    // Iterate over all h0, h2 combinations
    // Ignore used hits
    const auto h0_first_candidate = h0_candidates[2 * h1_index];
    const auto h0_size = h0_candidates[2 * h1_index + 1];
    const auto h2_first_candidate = h2_candidates[2 * h1_index];
    const auto h2_size = h2_candidates[2 * h1_index + 1];

    // Iterate over h0
    for (int h0_index = h0_first_candidate; h0_index < h0_first_candidate + h0_size; ++h0_index) {
      if (!hit_used[h0_index]) {
        // Fetch h0
        const Velo::HitBase h0 {velo_cluster_container.x(h0_index),
                                velo_cluster_container.y(h0_index),
                                velo_cluster_container.z(h0_index)};

        // Finally, iterate over all h2 indices
        for (auto h2_index = h2_first_candidate; h2_index < h2_first_candidate + h2_size; ++h2_index) {
          if (!hit_used[h2_index]) {
            // Our triplet is h0_index, h1_index, h2_index
            // Fit it and check if it's better than what this thread had
            // for any triplet with h1
            const Velo::HitBase h2 {velo_cluster_container.x(h2_index),
                                    velo_cluster_container.y(h2_index),
                                    velo_cluster_container.z(h2_index)};

            // Calculate prediction
            const auto z2_tz = (h2.z - h0.z) / (h1.z - h0.z);
            const auto x = h0.x + (h1.x - h0.x) * z2_tz;
            const auto y = h0.y + (h1.y - h0.y) * z2_tz;
            const auto dx = x - h2.x;
            const auto dy = y - h2.y;

            // Calculate fit
            const auto scatter = (dx * dx) + (dy * dy);

            if (scatter < best_fit) {
              // Populate fit, h0 and h2 in case we have found a better one
              best_fit = scatter;
              best_h0 = h0_index;
              best_h2 = h2_index;
            }
          }
        }
      }
    }

    if (best_fit < Configuration::velo_search_by_triplet::max_scatter_seeding) {
      // Add the track to the bag of tracks
      const auto trackP =
        atomicAdd(dev_atomics_velo + 1, 1) & Configuration::velo_search_by_triplet::ttf_modulo_mask;
      tracklets[trackP] = Velo::TrackletHits {best_h0, h1_index, best_h2};

      // Add the tracks to the bag of tracks to_follow
      // Note: The first bit flag marks this is a tracklet (hitsNum == 3),
      // and hence it is stored in tracklets
      const auto ttfP =
        atomicAdd(dev_atomics_velo + 2, 1) & Configuration::velo_search_by_triplet::ttf_modulo_mask;
      tracks_to_follow[ttfP] = 0x80000000 | trackP;
    }
  }
}
