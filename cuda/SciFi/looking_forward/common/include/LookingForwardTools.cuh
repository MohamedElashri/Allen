#pragma once

#include <tuple>
#include "States.cuh"
#include "SciFiEventModel.cuh"
#include "LookingForwardConstants.cuh"

namespace LookingForward {
  // straight line extrapolation of y to other z position
  __device__ inline float y_at_z(const MiniState& state, const float z) { return state.y + (z - state.z) * state.ty; }

  __device__ MiniState propagate_state_from_velo_multi_par(
    const MiniState& UT_state,
    const float qop,
    const int layer,
    const LookingForward::Constants* dev_looking_forward_constants);

  __device__ inline float linear_propagation(float x_0, float tx, float dz) { return x_0 + tx * dz; }

  // straight line extrapolation of MiniState to other z position
  __device__ inline MiniState state_at_z(const MiniState& state, const float z)
  {
    return {state.x + (z - state.z) * state.tx, state.y + (z - state.z) * state.ty, z, state.tx, state.ty};
  }

  __device__ inline float y_at_z_dzdy_corrected(const MiniState& state, const float z)
  {
    return (state.y + (z - state.z) * state.ty) / (1.f - state.ty * SciFi::Constants::dzdy);
  }

  __device__ inline void state_at_z_dzdy_corrected(MiniState& state, const float z)
  {
    state.x += (z - state.z) * state.tx;
    state.y = y_at_z_dzdy_corrected(state, z);
    state.z = z;
  }

  __device__ float propagate_x_from_velo_multi_par(
    const MiniState& UT_state,
    const float qop,
    const int layer,
    const LookingForward::Constants* dev_looking_forward_constants);

  __device__ float tx_ty_corr_multi_par(
    const MiniState& ut_state,
    const int station,
    const LookingForward::Constants* dev_looking_forward_constants);
  
  __device__ std::tuple<float, float, float> lms_y_fit(
    const SciFi::TrackHits& track,
    const uint number_of_uv_hits,
    const SciFi::Hits& scifi_hits,
    const float a1,
    const float b1,
    const float c1,
    const float d_ratio,
    const uint event_offset,
    const LookingForward::Constants* dev_looking_forward_constants);
} // namespace LookingForward
