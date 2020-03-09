#pragma once

#include "VeloEventModel.cuh"
#include "BinarySearch.cuh"
#include <tuple>

__device__ void track_forwarding(
  Velo::ConstClusters& velo_cluster_container,
  const float* hit_phi,
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
  const int ttf_modulo_mask,
  const uint ttf_modulo,
  const float max_scatter_forwarding,
  const uint max_skipped_modules);

/**
 * @brief Finds candidates in the specified module.
 */
template<typename T>
__device__ std::tuple<int, int> find_forward_candidates(
  const Velo::Module& module,
  const float tx,
  const float ty,
  const float* hit_Phis,
  const Velo::HitBase& h0,
  const T calculate_hit_phi,
  const float forward_phi_tolerance)
{
  const auto dz = module.z - h0.z;
  const auto predx = tx * dz;
  const auto predy = ty * dz;
  const auto x_prediction = h0.x + predx;
  const auto y_prediction = h0.y + predy;
  const auto track_extrapolation_phi = calculate_hit_phi(x_prediction, y_prediction);

  const float min_value_phi {track_extrapolation_phi - forward_phi_tolerance};
  const int first_candidate = binary_search_leftmost(hit_Phis + module.hitStart, module.hitNums, min_value_phi);

  const float max_value_phi {track_extrapolation_phi + forward_phi_tolerance};
  const int size = binary_search_leftmost(
    hit_Phis + module.hitStart + first_candidate, module.hitNums - first_candidate, max_value_phi);

  return {module.hitStart + first_candidate, size};
}
