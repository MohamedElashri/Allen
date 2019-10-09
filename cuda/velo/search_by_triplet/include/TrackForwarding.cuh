#pragma once

#include "VeloEventModel.cuh"
#include "BinarySearch.cuh"
#include <tuple>

__device__ void track_forwarding(
  const float* dev_velo_cluster_container,
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
  const int ip_shift);

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
  const T calculate_hit_phi)
{
  const auto dz = module.z - h0.z;
  const auto predx = tx * dz;
  const auto predy = ty * dz;
  const auto x_prediction = h0.x + predx;
  const auto y_prediction = h0.y + predy;
  const auto track_extrapolation_phi = calculate_hit_phi(x_prediction, y_prediction);

  int first_candidate = -1, last_candidate = -1;
  first_candidate = binary_search_first_candidate(
    hit_Phis + module.hitStart, module.hitNums, track_extrapolation_phi, Velo::Tracking::forward_phi_tolerance);

  if (first_candidate != -1) {
    // Find last candidate
    last_candidate = binary_search_second_candidate(
      hit_Phis + module.hitStart + first_candidate,
      module.hitNums - first_candidate,
      track_extrapolation_phi,
      Velo::Tracking::forward_phi_tolerance);
    first_candidate += module.hitStart;
    last_candidate = first_candidate + last_candidate;
  }

  return std::tuple<int, int> {first_candidate, last_candidate};
}
