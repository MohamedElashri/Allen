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
  const float forward_phi_tolerance);

__device__ void track_seeding(
  Velo::ConstClusters& velo_cluster_container,
  const Velo::Module* module_data,
  bool* hit_used,
  Velo::TrackletHits* tracklets,
  uint* tracks_to_follow,
  unsigned short* h1_rel_indices,
  uint* dev_shifted_atomics_velo,
  const float max_scatter_seeding,
  const int16_t* hit_phi);

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
  const float forward_phi_tolerance,
  const float max_scatter_forwarding,
  const uint max_skipped_modules);

/**
 * @brief Finds candidates in the specified module.
 */
__device__ inline std::tuple<int, int> find_forward_candidates(
  const Velo::Module& module,
  const float tx,
  const float ty,
  const int16_t* hit_Phis,
  const Velo::HitBase& h0,
  const int16_t forward_phi_tolerance)
{
  const auto dz = module.z - h0.z;
  const auto predx = tx * dz;
  const auto predy = ty * dz;
  const auto x_prediction = h0.x + predx;
  const auto y_prediction = h0.y + predy;
  const int16_t track_extrapolation_phi = hit_phi_16(x_prediction, y_prediction);

  const int16_t min_value_phi = track_extrapolation_phi - forward_phi_tolerance;
  const int first_candidate = binary_search_leftmost(hit_Phis + module.hit_start, module.hit_num, min_value_phi);

  const int16_t max_value_phi = track_extrapolation_phi + forward_phi_tolerance;
  const int size = binary_search_leftmost(
    hit_Phis + module.hit_start + first_candidate, module.hit_num - first_candidate, max_value_phi);

  return {module.hit_start + first_candidate, size};
}

/**
 * @brief Finds candidates in the specified module.
 */
__device__ inline int find_seeding_candidate(
  const Velo::Module& module,
  const float tx,
  const float ty,
  const int16_t* hit_Phis,
  const Velo::HitBase& h0,
  const float previous_module_z)
{
  const auto dz = module.z - previous_module_z;
  const auto predx = tx * dz;
  const auto predy = ty * dz;
  const auto x_prediction = h0.x + predx;
  const auto y_prediction = h0.y + predy;
  const auto track_extrapolation_phi = hit_phi_16(x_prediction, y_prediction);

  return binary_search_leftmost(hit_Phis + module.hit_start, module.hit_num, track_extrapolation_phi);
}
