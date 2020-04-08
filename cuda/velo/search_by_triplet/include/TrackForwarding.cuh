#pragma once

#include "VeloEventModel.cuh"
#include "BinarySearch.cuh"
#include "VeloTools.cuh"
#include <tuple>

__device__ void process_modules(
  Velo::Module* module_data,
  bool* hit_used,
  const uint* module_hit_start,
  const uint* module_hit_num,
  Velo::ConstClusters& velo_cluster_container,
  const int16_t* hit_phi,
  uint* tracks_to_follow,
  Velo::TrackletHits* weak_tracks,
  Velo::TrackletHits* tracklets,
  Velo::TrackHits* tracks,
  unsigned short* h1_rel_indices,
  const uint hit_offset,
  const float* dev_velo_module_zs,
  uint* dev_atomics_velo,
  uint* dev_number_of_velo_tracks,
  const float max_scatter_seeding,
  const float max_scatter_forwarding,
  const uint max_skipped_modules,
  const int16_t seeding_phi_tolerance,
  const int16_t forward_phi_tolerance);

__device__ void track_seeding(
  Velo::ConstClusters& velo_cluster_container,
  const Velo::Module* module_data,
  bool* hit_used,
  Velo::TrackletHits* tracklets,
  uint* tracks_to_follow,
  unsigned short* h1_rel_indices,
  uint* dev_shifted_atomics_velo,
  const float max_scatter_seeding,
  const int16_t* hit_phi,
  const int16_t seeding_phi_tolerance);

__device__ void track_forwarding(
  Velo::ConstClusters& velo_cluster_container,
  const int16_t* hit_phi,
  bool* hit_used,
  const Velo::Module* module_data,
  const uint diff_ttf,
  uint* tracks_to_follow,
  Velo::TrackletHits* weak_tracks,
  const uint prev_ttf,
  Velo::TrackletHits* tracklets,
  Velo::TrackHits* tracks,
  uint* dev_atomics_velo,
  uint* dev_number_of_velo_tracks,
  const int16_t forward_phi_tolerance,
  const float max_scatter_forwarding,
  const uint max_skipped_modules);

/**
 * @brief Returns the first possible candidate, according to
 *        extrapolation of the track to phi minus the tolerance.
 *        Returns the candidate, and the extrapolated phi value.
 */
__device__ inline std::tuple<int, int16_t> find_forward_candidate(
  const Velo::Module& module,
  const int16_t* hit_Phis,
  const Velo::HitBase& h0,
  const float tx,
  const float ty,
  const float dz,
  const int16_t forward_phi_tolerance)
{
  const auto predx = tx * dz;
  const auto predy = ty * dz;
  const auto x_prediction = h0.x + predx;
  const auto y_prediction = h0.y + predy;
  const auto track_extrapolation_phi = hit_phi_16(x_prediction, y_prediction);

  return {binary_search_leftmost(
            hit_Phis + module.hit_start,
            module.hit_num,
            static_cast<int16_t>(track_extrapolation_phi - forward_phi_tolerance)),
          track_extrapolation_phi};
}
