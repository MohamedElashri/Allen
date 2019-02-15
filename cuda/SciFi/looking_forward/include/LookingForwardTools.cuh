#pragma once

#include <tuple>
#include "MiniState.cuh"
#include "SciFiEventModel.cuh"
#include "LookingForwardConstants.cuh"

namespace LookingForward {
  // straight line extrapolation of MiniState to other z position
  __device__ MiniState state_at_z(const MiniState& state, const float z);

  __device__ float x_at_z(const MiniState& state, const float z);

  // straight line extrapolation of y to other z position
  __device__ float y_at_z(const MiniState& state, const float z);

  __device__ float linear_propagation(float x_0, float tx, float dz);

  __device__ MiniState propagate_state_from_velo(
    const MiniState& UT_state,
    float qop,
    int layer,
    const LookingForward::Constants* dev_looking_forward_constants);

  __device__ float dx_calc(const float qop);

  __device__ std::tuple<int, int> find_x_in_window(
    const SciFi::Hits& hits,
    const int zone_offset,
    const int num_hits,
    const float x_min,
    const float x_max);

  // access hits from a layer
  // first zone number: y < 0
  // second zone number: y > 0
  __device__ std::tuple<int, int>
  get_offset_and_n_hits_for_layer(const int first_zone, const SciFi::HitCount& scifi_hit_count, const float y);
} // namespace LookingForward
