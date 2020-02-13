#include "SearchByTriplet.cuh"
#include "VeloTools.cuh"
#include <cstdio>

/**
 * @brief Performs the track forwarding of forming tracks
 */
__device__ void track_forwarding(
  Velo::ConstClusters& velo_cluster_container,
  const float* hit_phi,
  bool* hit_used,
  const Velo::Module* module_data,
  const uint diff_ttf,
  uint* tracks_to_follow,
  Velo::TrackletHits* three_hit_tracks,
  const uint prev_ttf,
  Velo::TrackletHits* tracklets,
  Velo::TrackHits* tracks,
  uint* dev_atomics_velo,
  uint* dev_number_of_velo_tracks,
  const float forward_phi_tolerance,
  const int ttf_modulo_mask,
  [[maybe_unused]] const uint ttf_modulo,
  const float max_scatter_forwarding,
  const uint max_skipped_modules)
{
  // Assign a track to follow to each thread
  for (uint ttf_element = threadIdx.x; ttf_element < diff_ttf; ttf_element += blockDim.x) {
    const auto full_track_number =
      tracks_to_follow[(prev_ttf + ttf_element) & ttf_modulo_mask];
    const bool track_flag = (full_track_number & 0x80000000) == 0x80000000;
    const auto skipped_modules = (full_track_number & 0x70000000) >> 28;
    auto track_number = full_track_number & 0x0FFFFFFF;

    assert(
      track_flag ? track_number < ttf_modulo :
                   track_number < Velo::Constants::max_tracks);

    uint number_of_hits;
    Velo::TrackHits* t;

    if (track_flag) {
      t = (Velo::TrackHits*) &(tracklets[track_number]);
      number_of_hits = 3;
    }
    else {
      t = tracks + track_number;
      number_of_hits = t->hitsNum;
    }

    // Load last two hits in h0, h1
    const auto h0_num = t->hits[number_of_hits - 2];
    const auto h1_num = t->hits[number_of_hits - 1];

    const Velo::HitBase h0 {
      velo_cluster_container.x(h0_num), velo_cluster_container.y(h0_num), velo_cluster_container.z(h0_num)};

    const Velo::HitBase h1 {
      velo_cluster_container.x(h1_num), velo_cluster_container.y(h1_num), velo_cluster_container.z(h1_num)};

    // Track forwarding over t, for all hits in the next module
    // Line calculations
    const auto td = 1.0f / (h1.z - h0.z);
    const auto txn = (h1.x - h0.x);
    const auto tyn = (h1.y - h0.y);
    const auto tx = txn * td;
    const auto ty = tyn * td;

    // Find the best candidate
    float best_fit = max_scatter_forwarding;
    int best_h2 = -1;

    // Get candidates by performing a binary search in expected phi
    const auto odd_module_candidates = find_forward_candidates(
      module_data[2],
      tx,
      ty,
      hit_phi,
      h0,
      [](const float x, const float y) { return hit_phi_odd(x, y); },
      forward_phi_tolerance);

    const auto even_module_candidates = find_forward_candidates(
      module_data[3],
      tx,
      ty,
      hit_phi,
      h0,
      [](const float x, const float y) { return hit_phi_even(x, y); },
      forward_phi_tolerance);

    // Search on both modules in the same for loop
    const int total_odd_candidates = std::get<1>(odd_module_candidates) - std::get<0>(odd_module_candidates);
    const int total_even_candidates = std::get<1>(even_module_candidates) - std::get<0>(even_module_candidates);
    const int total_candidates = total_odd_candidates + total_even_candidates;

    for (int j = 0; j < total_candidates; ++j) {
      const int h2_index = j < total_odd_candidates ? std::get<0>(odd_module_candidates) + j :
                                                      std::get<0>(even_module_candidates) + j - total_odd_candidates;

      const Velo::HitBase h2 {
        velo_cluster_container.x(h2_index), velo_cluster_container.y(h2_index), velo_cluster_container.z(h2_index)};

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
      hit_used[best_h2] = true;

      // Update the track in the bag
      if (number_of_hits == 3) {
        // Also mark the first three as used
        hit_used[t->hits[0]] = true;
        hit_used[t->hits[1]] = true;
        hit_used[t->hits[2]] = true;

        // If it is a track made out of less than or equal to 4 hits,
        // we have to allocate it in the tracks pointer
        track_number = atomicAdd(dev_number_of_velo_tracks + blockIdx.x, 1);
        tracks[track_number].hits[0] = t->hits[0];
        tracks[track_number].hits[1] = t->hits[1];
        tracks[track_number].hits[2] = t->hits[2];
        tracks[track_number].hits[3] = best_h2;
        tracks[track_number].hitsNum = 4;
      }
      else {
        t->hits[t->hitsNum++] = best_h2;
      }

      if (number_of_hits + 1 < Velo::Constants::max_track_size) {
        // Add the tracks to the bag of tracks to_follow
        const auto ttf_p = atomicAdd(dev_atomics_velo + 2, 1) & ttf_modulo_mask;
        tracks_to_follow[ttf_p] = track_number;
      }
    }
    // A track just skipped a module
    // We keep it for another round
    else if (skipped_modules < max_skipped_modules) {
      // Form the new mask
      track_number = ((skipped_modules + 1) << 28) | (full_track_number & 0x8FFFFFFF);

      // Add the tracks to the bag of tracks to_follow
      const auto ttf_p = atomicAdd(dev_atomics_velo + 2, 1) & ttf_modulo_mask;
      tracks_to_follow[ttf_p] = track_number;
    }
    // If there are only three hits in this track,
    // mark it as "doubtful"
    else if (number_of_hits == 3) {
      const auto three_hit_tracks_p = atomicAdd(dev_atomics_velo, 1);
      three_hit_tracks[three_hit_tracks_p] = Velo::TrackletHits {t->hits[0], t->hits[1], t->hits[2]};
    }
    // In the "else" case, we couldn't follow up the track,
    // so we won't be track following it anymore.
  }
}
