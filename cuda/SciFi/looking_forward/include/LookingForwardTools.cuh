#pragma once

namespace LookingForward {
  // straight line extrapolation of MiniState to other z position
  __device__ MiniState state_at_z(const MiniState& state, const float z);

  // straight line extrapolation of y to other z position
  __device__ float y_at_z(const MiniState& state, const float z);

  __device__ MiniState propagate_state_from_velo(const MiniState& UT_state, float qop, int layer);

  __device__ float dx_calc(const float qop);

  __device__ void
  linear_regression(const std::vector<float>& x, const std::vector<float>& y, float& m, float& q, float& chi_2);

  __device__ float
  get_chi_2(const std::vector<float>& x, const std::vector<float>& y, std::function<float(float)> expected_function);
  
  __device__ std::tuple<int, int> find_x_in_window(
    const SciFi::Hits& hits,
    const int zone_offset,
    const int num_hits,
    const float x_min,
    const float x_max);
} // namespace LookingForward
