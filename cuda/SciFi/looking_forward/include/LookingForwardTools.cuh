#pragma once

namespace LookingForward {
  // straight line extrapolation of MiniState to other z position
  __device__ MiniState state_at_z(const MiniState& state, const float z);

  // straight line extrapolation of y to other z position
  __device__ float y_at_z(const MiniState& state, const float z);

  __device__ MiniState propagate_state_from_velo(const MiniState& UT_state, float qop, int layer);

  __device__ float dx_calc(const float qop);
} // namespace LookingForward
