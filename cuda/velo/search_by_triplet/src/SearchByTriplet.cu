#include "ProcessModules.cuh"
#include "TrackSeeding.cuh"
#include "TrackForwarding.cuh"
#include "ClusteringDefinitions.cuh"
#include "SearchByTriplet.cuh"
#include "VeloTools.cuh"
#include <cstdio>

/**
 * @brief Track forwarding algorithm based on triplet finding
 * @detail For details, check out paper
 *         "A fast local algorithm for track reconstruction on parallel architectures"
 */
__global__ void velo_search_by_triplet::velo_search_by_triplet(
  velo_search_by_triplet::Parameters parameters,
  const VeloGeometry* dev_velo_geometry)
{
  /* Data initialization */
  // Each event is treated with two blocks, one for each side.
  const uint event_number = blockIdx.x;
  const uint number_of_events = gridDim.x;
  const uint tracks_offset = event_number * Velo::Constants::max_tracks;

  // Pointers to data within the event
  const uint total_estimated_number_of_clusters =
    parameters.dev_offsets_estimated_input_size[Velo::Constants::n_modules * number_of_events];
  const uint* module_hitStarts =
    parameters.dev_offsets_estimated_input_size + event_number * Velo::Constants::n_modules;
  const uint* module_hitNums = parameters.dev_module_cluster_num + event_number * Velo::Constants::n_modules;
  const uint hit_offset = module_hitStarts[0];

  // Think whether this offset'ed container is a good solution
  const auto velo_cluster_container = Velo::ConstClusters {
    parameters.dev_sorted_velo_cluster_container, total_estimated_number_of_clusters, hit_offset};

  const auto hit_phi = parameters.dev_hit_phi + hit_offset;

  // Per event datatypes
  Velo::TrackHits* tracks = parameters.dev_tracks + tracks_offset;

  // Per side datatypes
  bool* hit_used = parameters.dev_hit_used + hit_offset;

  uint* tracks_to_follow =
    parameters.dev_tracks_to_follow + event_number * parameters.ttf_modulo;
  Velo::TrackletHits* three_hit_tracks =
    parameters.dev_three_hit_tracks + event_number * parameters.max_weak_tracks;
  Velo::TrackletHits* tracklets =
    parameters.dev_tracklets + event_number * parameters.ttf_modulo;
  unsigned short* h1_rel_indices = parameters.dev_rel_indices + event_number * 2000;

  // Shared memory size is defined externally
  __shared__ float module_data[18];

  process_modules(
    (Velo::Module*) &module_data[0],
    hit_used,
    module_hitStarts,
    module_hitNums,
    velo_cluster_container,
    hit_phi,
    tracks_to_follow,
    three_hit_tracks,
    tracklets,
    tracks,
    h1_rel_indices,
    hit_offset,
    dev_velo_geometry->module_zs,
    parameters.dev_atomics_velo + blockIdx.x * Velo::num_atomics,
    parameters.dev_number_of_velo_tracks,
    parameters.ttf_modulo_mask,
    parameters.max_scatter_seeding,
    parameters.ttf_modulo,
    parameters.max_scatter_forwarding,
    parameters.max_skipped_modules,
    parameters.forward_phi_tolerance);
}

/**
 * @brief Processes modules in decreasing order with some stride
 */
__device__ void process_modules(
  Velo::Module* module_data,
  bool* hit_used,
  const uint* module_hitStarts,
  const uint* module_hitNums,
  Velo::ConstClusters& velo_cluster_container,
  const float* hit_phi,
  uint* tracks_to_follow,
  Velo::TrackletHits* weak_tracks,
  Velo::TrackletHits* tracklets,
  Velo::TrackHits* tracks,
  unsigned short* h1_rel_indices,
  const uint hit_offset,
  const float* dev_velo_module_zs,
  uint* dev_atomics_velo,
  uint* dev_number_of_velo_tracks,
  const int ttf_modulo_mask,
  const float max_scatter_seeding,
  const uint ttf_modulo,
  const float max_scatter_forwarding,
  const uint max_skipped_modules,
  const float forward_phi_tolerance)
{
  auto first_module = VP::NModules - 1;

  // Prepare the first seeding iteration
  // Load shared module information
  for (uint i = threadIdx.x; i < 6; i += blockDim.x) {
    const auto module_number = first_module - i;
    module_data[i].hitStart = module_hitStarts[module_number] - hit_offset;
    module_data[i].hitNums = module_hitNums[module_number];
    module_data[i].z = dev_velo_module_zs[module_number];
  }

  // Due to shared module data loading
  __syncthreads();

  // Do first track seeding
  track_seeding(
    velo_cluster_container,
    module_data,
    hit_used,
    tracklets,
    tracks_to_follow,
    h1_rel_indices,
    dev_atomics_velo,
    max_scatter_seeding,
    ttf_modulo_mask,
    hit_phi);

  // Prepare forwarding - seeding loop
  uint last_ttf = 0;
  first_module -= 2;

  while (first_module > 4) {

    // Due to WAR between trackSeedingFirst and the code below
    __syncthreads();

    // Iterate in modules
    // Load in shared
    for (int i = threadIdx.x; i < 6; i += blockDim.x) {
      const auto module_number = first_module - i;
      module_data[i].hitStart = module_hitStarts[module_number] - hit_offset;
      module_data[i].hitNums = module_hitNums[module_number];
      module_data[i].z = dev_velo_module_zs[module_number];
    }

    const auto prev_ttf = last_ttf;
    last_ttf = dev_atomics_velo[2];
    const auto diff_ttf = last_ttf - prev_ttf;

    // Reset atomics
    // Note: local_number_of_hits
    dev_atomics_velo[3] = 0;

    // Due to module data loading
    __syncthreads();

    // Track Forwarding
    track_forwarding(
      velo_cluster_container,
      hit_phi,
      hit_used,
      module_data,
      diff_ttf,
      tracks_to_follow,
      weak_tracks,
      prev_ttf,
      tracklets,
      tracks,
      dev_atomics_velo,
      dev_number_of_velo_tracks,
      forward_phi_tolerance,
      ttf_modulo_mask,
      ttf_modulo,
      max_scatter_forwarding,
      max_skipped_modules);

    // Due to ttf_insert_pointer
    __syncthreads();

    // Seeding
    track_seeding(
      velo_cluster_container,
      module_data,
      hit_used,
      tracklets,
      tracks_to_follow,
      h1_rel_indices,
      dev_atomics_velo,
      max_scatter_seeding,
      ttf_modulo_mask,
      hit_phi);

    first_module -= 2;
  }

  // Due to last seeding ttf_insert_pointer
  __syncthreads();

  const auto prev_ttf = last_ttf;
  last_ttf = dev_atomics_velo[2];
  const auto diff_ttf = last_ttf - prev_ttf;

  // Process the last bunch of track_to_follows
  for (uint ttf_element = threadIdx.x; ttf_element < diff_ttf; ttf_element += blockDim.x) {
    const int fulltrackno =
      tracks_to_follow[(prev_ttf + ttf_element) & ttf_modulo_mask];
    const bool track_flag = (fulltrackno & 0x80000000) == 0x80000000;
    const int trackno = fulltrackno & 0x0FFFFFFF;

    // Here we are only interested in three-hit tracks,
    // to mark them as "doubtful"
    if (track_flag) {
      const auto weakP = atomicAdd(dev_atomics_velo, 1);
      weak_tracks[weakP] = tracklets[trackno];
    }
  }
}

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
      module_data[4],
      tx,
      ty,
      hit_phi,
      h0,
      [](const float x, const float y) { return hit_phi_odd(x, y); },
      forward_phi_tolerance);

    const auto even_module_candidates = find_forward_candidates(
      module_data[5],
      tx,
      ty,
      hit_phi,
      h0,
      [](const float x, const float y) { return hit_phi_even(x, y); },
      forward_phi_tolerance);

    // Search on both modules in the same for loop
    const int total_odd_candidates = std::get<1>(odd_module_candidates);
    const int total_even_candidates = std::get<1>(even_module_candidates);
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

struct VeloCombinedValue {
  float value = 1000.f;
  int index = -1;
};

template<class T>
__device__ void compare_and_swap(T& a, T& b)
{
  if (a.value < b.value) {
    const T temp = a;
    a = b;
    b = temp;
  }
}

/**
 * @brief Search for compatible triplets in
 *        three neighbouring modules on one side
 */
__device__ void track_seeding(
  Velo::ConstClusters& velo_cluster_container,
  const Velo::Module* module_data,
  bool* hit_used,
  Velo::TrackletHits* tracklets,
  uint* tracks_to_follow,
  unsigned short* h1_indices,
  uint* dev_atomics_velo,
  const float max_scatter_seeding,
  const int ttf_modulo_mask,
  const float* hit_phi)
{
  // Add to an array all non-used h1 hits
  for (auto module_index : {2, 3}) {
    for (uint h1_rel_index = threadIdx.x; h1_rel_index < module_data[module_index].hitNums; h1_rel_index += blockDim.x) {
      const auto h1_index = module_data[module_index].hitStart + h1_rel_index;
      if (!hit_used[h1_index]) {
        const auto current_hit = atomicAdd(dev_atomics_velo + 3, 1);
        const auto oddity = module_index % 2;
        h1_indices[current_hit] = (oddity << 15) | h1_index;
      }
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
    float best_fit = max_scatter_seeding;

    // Fetch h1
    const auto h1_index_total = h1_indices[h1_rel_index];
    h1_index = h1_index_total & 0x7FFF;
    const auto oddity = h1_index_total >> 15;

    const Velo::HitBase h1 {velo_cluster_container.x(h1_index),
                            velo_cluster_container.y(h1_index),
                            velo_cluster_container.z(h1_index)};
    const auto h1_phi = hit_phi[h1_index];

    // Get best h0s
    constexpr int h0s_to_consider = 3;
    VeloCombinedValue best_h0s[h0s_to_consider];

    // Iterate over all h2 combinations
    for (uint h0_rel_index = 0; h0_rel_index < module_data[oddity].hitNums; ++h0_rel_index) {
      const auto h0_index = module_data[oddity].hitStart + h0_rel_index;
      if (!hit_used[h0_index]) {
        const auto h0_phi = hit_phi[h0_index];
        VeloCombinedValue combined_value {fabsf(h1_phi - h0_phi), static_cast<int>(h0_index)};

        compare_and_swap(combined_value, best_h0s[0]);
        compare_and_swap(best_h0s[0], best_h0s[1]);
        compare_and_swap(best_h0s[1], best_h0s[2]);
      }
    }

    // Use the best_h2s to find the best triplet
    for (uint h2_rel_index = 0; h2_rel_index < module_data[4 + oddity].hitNums; ++h2_rel_index) {
      const auto h2_index = module_data[4 + oddity].hitStart + h2_rel_index;
      if (!hit_used[h2_index]) {
        const Velo::HitBase h2 {velo_cluster_container.x(h2_index),
                                velo_cluster_container.y(h2_index),
                                velo_cluster_container.z(h2_index)};

        for (int i = 0; i < h0s_to_consider; ++i) {
          const auto h0_index = best_h0s[i].index;
          if (h0_index != -1) {
            const Velo::HitBase h0 {velo_cluster_container.x(h0_index),
                                    velo_cluster_container.y(h0_index),
                                    velo_cluster_container.z(h0_index)};

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

    if (best_fit < max_scatter_seeding) {
      // Add the track to the bag of tracks
      const auto trackP =
        atomicAdd(dev_atomics_velo + 1, 1) & ttf_modulo_mask;
      tracklets[trackP] = Velo::TrackletHits {best_h0, h1_index, best_h2};

      // Add the tracks to the bag of tracks to_follow
      // Note: The first bit flag marks this is a tracklet (hitsNum == 3),
      // and hence it is stored in tracklets
      const auto ttfP =
        atomicAdd(dev_atomics_velo + 2, 1) & ttf_modulo_mask;
      tracks_to_follow[ttfP] = 0x80000000 | trackP;
    }
  }
}
