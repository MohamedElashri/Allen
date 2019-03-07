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

  __device__ float scifi_propagation(const float x_0, const float tx, const float qop, const float dz);

  __device__ MiniState propagate_state_from_velo(
    const MiniState& UT_state,
    float qop,
    int layer,
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

  // access hits from a layer
  // first zone number: y < 0
  // second zone number: y > 0
  __device__ std::tuple<int, int>
  get_offset_and_n_hits_for_layer(const int first_zone, const SciFi::HitCount& scifi_hit_count, const float y);

  /**
   * @brief Variadic templated chi2.
   */
  template<typename Pairs>
  struct chi2_impl;

  template<>
  struct chi2_impl<std::tuple<>> {
    __device__ constexpr static float calculate(const float m, const float q) {
      return 0.f;
    }
  };

  template<typename X, typename Y, typename... Pairs>
  struct chi2_impl<std::tuple<std::tuple<X, Y>, Pairs...>> {
    __device__ constexpr static float calculate(const float m, const float q, std::tuple<X, Y> pair, Pairs... pairs) {
      const auto expected_y = m * std::get<0>(pair) + q;
      const auto contribution = (std::get<1>(pair) - expected_y) * (std::get<1>(pair) - expected_y);
      return chi2_impl<std::tuple<Pairs...>>::calculate(m, q, pairs...) + contribution;
    }
  };

  template<typename... T>
  __device__ constexpr float chi2(
    const float m,
    const float q,
    const T&... pairs)
  {
    return chi2_impl<std::tuple<T...>>::calculate(m, q, pairs...);
  }

  // // We need a new lambda to compare in chi2
  // const auto chi2_fn = [&x_at_layer_8, &reco_slope, &candidate] (const float z) {
  //   return scifi_propagation(
  //     x_at_layer_8,
  //     reco_slope,
  //     candidate.qop,
  //     z - SciFi::LookingForward::Zone_zPos[8]);
  // };
  
  /**
   * @brief Variadic templated chi2.
   */
  template<typename Pairs>
  struct chi2_extrapolation_impl;

  template<>
  struct chi2_extrapolation_impl<std::tuple<>> {
    __device__ constexpr static float calculate(
      const float x_at_layer_8,
      const float z_at_layer_8,
      const float reco_slope,
      const float qop)
    {
      return 0.f;
    }
  };

  template<typename X, typename Y, typename... Pairs>
  struct chi2_extrapolation_impl<std::tuple<std::tuple<X, Y>, Pairs...>> {
    __device__ constexpr static float calculate(
      const float x_at_layer_8,
      const float z_at_layer_8,
      const float reco_slope,
      const float qop,
      std::tuple<X, Y> pair,
      Pairs... pairs)
    {
      const auto expected_y = scifi_propagation(
        x_at_layer_8,
        reco_slope,
        qop,
        std::get<0>(pair) - z_at_layer_8);

      const auto contribution = (std::get<1>(pair) - expected_y) * (std::get<1>(pair) - expected_y);
      return chi2_extrapolation_impl<std::tuple<Pairs...>>::calculate(
        x_at_layer_8,
        z_at_layer_8,
        reco_slope,
        qop,
        pairs...) + contribution;
    }
  };
  
  template<typename... T>
  __device__ constexpr float chi2_extrapolation(
    const float x_at_layer_8,
    const float z_at_layer_8,
    const float reco_slope,
    const float qop,
    const T&... pairs)
  {
    return chi2_extrapolation_impl<std::tuple<T...>>::calculate(
      x_at_layer_8, z_at_layer_8, reco_slope, qop, pairs...);
  }

  __device__ std::tuple<int, float> get_best_hit(
    const SciFi::Hits& hits,
    const SciFi::HitCount& hit_count,
    const float m,
    const std::tuple<int, int>& layer_candidates,
    const std::tuple<float, float>& hit_layer_0_z_x,
    const std::tuple<float, float>& hit_layer_3_z_x,
    const float layer_projected_state_z,
    const float layer_projected_state_y,
    const float dxdy);
} // namespace LookingForward
