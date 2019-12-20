#include "SearchByTriplet.cuh"
#include "VeloTools.cuh"
#include <cstdio>

/**
 * @brief Performs the track forwarding of forming tracks
 */
__device__ void track_forwarding(
  const Velo::Clusters<const uint>& velo_cluster_container,
  const float* hit_phi,
  bool* hit_used,
  const Velo::Module* module_data,
  const uint diff_ttf,
  uint* tracks_to_follow,
  Velo::TrackletHits* weak_tracks,
  const uint prev_ttf,
  Velo::TrackletHits* tracklets,
  Velo::TrackHits* tracks,
  const uint number_of_hits,
  uint* dev_atomics_velo,
  uint* dev_number_of_velo_tracks)
{
  // Assign a track to follow to each thread
  for (uint ttf_element = threadIdx.x; ttf_element < diff_ttf; ttf_element += blockDim.x) {
    const auto fulltrackno =
      tracks_to_follow[(prev_ttf + ttf_element) & Configuration::velo_search_by_triplet::ttf_modulo_mask];
    const bool track_flag = (fulltrackno & 0x80000000) == 0x80000000;
    const auto skipped_modules = (fulltrackno & 0x70000000) >> 28;
    auto trackno = fulltrackno & 0x0FFFFFFF;
    assert(
      track_flag ? trackno < Configuration::velo_search_by_triplet::ttf_modulo :
                   trackno < Velo::Constants::max_tracks);

    Velo::TrackHitsScratch track_scratch;
    Velo::TrackHits* t;

    if (track_flag) {
      track_scratch = tracklets[trackno];
      t = (Velo::TrackHits*) &track_scratch;
    }
    else {
      t = tracks + trackno;
    }

    // Load last two hits in h0, h1
    assert(t->hitsNum < Velo::Constants::max_track_size);
    const auto h0_num = t->hits[t->hitsNum - 2];
    const auto h1_num = t->hits[t->hitsNum - 1];

    assert(h0_num < number_of_hits);
    const Velo::HitBase h0 {velo_cluster_container.x(h0_num),
                            velo_cluster_container.y(h0_num),
                            velo_cluster_container.z(h0_num)};

    assert(h1_num < number_of_hits);
    const Velo::HitBase h1 {velo_cluster_container.x(h1_num),
                            velo_cluster_container.y(h1_num),
                            velo_cluster_container.z(h1_num)};

    // Track forwarding over t, for all hits in the next module
    // Line calculations
    const auto td = 1.0f / (h1.z - h0.z);
    const auto txn = (h1.x - h0.x);
    const auto tyn = (h1.y - h0.y);
    const auto tx = txn * td;
    const auto ty = tyn * td;

    // Find the best candidate
    float best_fit = Configuration::velo_search_by_triplet::max_scatter_forwarding;
    int best_h2 = -1;

    // Get candidates by performing a binary search in expected phi
    const auto odd_module_candidates = find_forward_candidates(
      module_data[2], tx, ty, hit_phi, h0, [](const float x, const float y) {
        return hit_phi_odd(x, y);
      });

    const auto even_module_candidates = find_forward_candidates(
      module_data[3], tx, ty, hit_phi, h0, [](const float x, const float y) {
        return hit_phi_even(x, y);
      });

    // Search on both modules in the same for loop
    const int total_odd_candidates = std::get<1>(odd_module_candidates) - std::get<0>(odd_module_candidates);
    const int total_even_candidates = std::get<1>(even_module_candidates) - std::get<0>(even_module_candidates);
    const int total_candidates = total_odd_candidates + total_even_candidates;

    for (int j = 0; j < total_candidates; ++j) {
      const int h2_index = j < total_odd_candidates ? std::get<0>(odd_module_candidates) + j :
                                                      std::get<0>(even_module_candidates) + j - total_odd_candidates;

      const Velo::HitBase h2 {velo_cluster_container.x(h2_index),
                              velo_cluster_container.y(h2_index),
                              velo_cluster_container.z(h2_index)};

      const auto dz = h2.z - h0.z;
      const auto predx = h0.x + tx * dz;
      const auto predy = h0.y + ty * dz;
      const auto dx = predx - h2.x;
      const auto dy = predy - h2.y;

      // Scatter
      const auto scatter = (dx * dx) + (dy * dy);

      // We keep the best one found
      if (scatter < best_fit) {
        best_fit = scatter;
        best_h2 = h2_index;
      }
    }

    // Condition for finding a h2
    if (best_h2 != -1) {
      // Mark h2 as used
      assert(best_h2 < (int) number_of_hits);
      hit_used[best_h2] = true;

      // Update the tracks to follow, we'll have to follow up
      // this track on the next iteration :)
      assert(t->hitsNum < Velo::Constants::max_track_size);
      t->hits[t->hitsNum++] = best_h2;

      // Update the track in the bag
      if (t->hitsNum <= 4) {
        assert(t->hits[0] < number_of_hits);
        assert(t->hits[1] < number_of_hits);
        assert(t->hits[2] < number_of_hits);

        // Also mark the first three as used
        hit_used[t->hits[0]] = true;
        hit_used[t->hits[1]] = true;
        hit_used[t->hits[2]] = true;

        // If it is a track made out of less than or equal to 4 hits,
        // we have to allocate it in the tracks pointer
        trackno = atomicAdd(dev_number_of_velo_tracks + blockIdx.x, 1);
        *((Velo::TrackHitsScratch*) &tracks[trackno]) = track_scratch;
      }

      // Add the tracks to the bag of tracks to_follow
      const auto ttfP =
        atomicAdd(dev_atomics_velo + 2, 1) & Configuration::velo_search_by_triplet::ttf_modulo_mask;
      tracks_to_follow[ttfP] = trackno;
    }
    // A track just skipped a module
    // We keep it for another round
    else if (skipped_modules < Configuration::velo_search_by_triplet::max_skipped_modules) {
      // Form the new mask
      trackno = ((skipped_modules + 1) << 28) | (fulltrackno & 0x8FFFFFFF);

      // Add the tracks to the bag of tracks to_follow
      const auto ttfP =
        atomicAdd(dev_atomics_velo + 2, 1) & Configuration::velo_search_by_triplet::ttf_modulo_mask;
      tracks_to_follow[ttfP] = trackno;
    }
    // If there are only three hits in this track,
    // mark it as "doubtful"
    else if (t->hitsNum == 3) {
      const auto weakP =
        atomicAdd(dev_atomics_velo, 1) & Configuration::velo_search_by_triplet::ttf_modulo_mask;
      assert(weakP < Configuration::velo_search_by_triplet::max_weak_tracks);
      weak_tracks[weakP] = Velo::TrackletHits {t->hits[0], t->hits[1], t->hits[2]};
    }
    // In the "else" case, we couldn't follow up the track,
    // so we won't be track following it anymore.
  }
}
