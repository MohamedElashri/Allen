#pragma once

#include <tuple>
#include "States.cuh"
#include "SciFiEventModel.cuh"
#include "LookingForwardConstants.cuh"

namespace LookingForward {
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

  __device__ inline float x_at_z(const MiniState& state, const float z) { return state.x + (z - state.z) * state.tx; }

  // straight line extrapolation of y to other z position
  __device__ inline float y_at_z(const MiniState& state, const float z) { return state.y + (z - state.z) * state.ty; }

  __device__ inline float linear_propagation(float x_0, float tx, float dz) { return x_0 + tx * dz; }

  __device__ inline float scifi_propagation(const float x_0, const float tx, const float qop, const float dz)
  {
    return linear_propagation(x_0, tx, dz) + LookingForward::forward_param * qop * dz * dz;
  }

  __device__ inline float get_extrap(const float qop, const float dz)
  {
    // return LookingForward::forward_param * qop * dz * dz;
    // new parametrization
    return (LookingForward::forward_param * dz * dz + LookingForward::d_ratio * dz * dz * dz) * qop;
  }
  __device__ float propagate_x_from_velo_multi_par(
    const MiniState& UT_state,
    const float qop,
    const int layer,
    const LookingForward::Constants* dev_looking_forward_constants);

  __device__ MiniState propagate_state_from_velo_multi_par(
    const MiniState& UT_state,
    const float qop,
    const int layer,
    const LookingForward::Constants* dev_looking_forward_constants);

  __device__ float dx_calc(const float state_tx, float qop);

  __device__ std::tuple<int, int> find_x_in_window(
    const SciFi::Hits& hits,
    const int zone_offset,
    const int num_hits,
    const float value,
    const float margin);

  __device__ std::tuple<int, int> find_x_in_window(
    const SciFi::Hits& hits,
    const int zone_offset,
    const int num_hits,
    const float value0,
    const float value1,
    const float margin);

  __device__ std::tuple<short, short> find_x_in_window(
    const float* hits_x0,
    const int zone_offset,
    const int num_hits,
    const float value,
    const float margin);

  // access hits from a layer
  // first zone number: y < 0
  // second zone number: y > 0
  __device__ std::tuple<int, int>
  get_offset_and_n_hits_for_layer(const int first_zone, const SciFi::HitCount& scifi_hit_count, const float y);

  __device__ float tx_ty_corr_multi_par(
    const MiniState& ut_state,
    const int station,
    const LookingForward::Constants* dev_looking_forward_constants);

  __device__ float qop_update_multi_par(
    const MiniState& ut_state_tx,
    const float h0_x,
    const float h0_z,
    const float h1_x,
    const float h1_z,
    const int station,
    const LookingForward::Constants* dev_looking_forward_constants);

  __device__ float qop_update_multi_par(
    const MiniState& ut_state_tx,
    const float slope,
    const int station,
    const LookingForward::Constants* dev_looking_forward_constants);

  // __device__ float qop_update(const float ut_state_tx, const float SciFi_tx, const float ds_p_param_layer_inv);
} // namespace LookingForward
