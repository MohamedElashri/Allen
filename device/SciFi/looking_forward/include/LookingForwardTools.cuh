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
    const LookingForward::Constants* dev_looking_forward_constants,
    const float* dev_magnet_polarity);

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

  __device__ inline float tx_ty_corr_multi_par(
    const MiniState& ut_state,
    const int station,
    const LookingForward::Constants* dev_looking_forward_constants,
    const float* dev_magnet_polarity)
  {
    float tx_ty_corr = 0.f;
    const float tx_pow[5] = {1,
                             ut_state.tx,
                             ut_state.tx * ut_state.tx,
                             ut_state.tx * ut_state.tx * ut_state.tx,
                             ut_state.tx * ut_state.tx * ut_state.tx * ut_state.tx};

    const float ty_pow[5] = {1,
                             ut_state.ty * (-1.f) * *dev_magnet_polarity,
                             ut_state.ty * ut_state.ty,
                             ut_state.ty * ut_state.ty * ut_state.ty * (-1.f) * *dev_magnet_polarity,
                             ut_state.ty * ut_state.ty * ut_state.ty * ut_state.ty};

    for (int i = 0; i < 5; i++) {
      for (int j = 0; j < 5; j++) {
        tx_ty_corr +=
          dev_looking_forward_constants->ds_multi_param[station * 5 * 5 + i * 5 + j] * tx_pow[i] * ty_pow[j];
      }
    }

    return tx_ty_corr;
  }

  __device__ inline MiniState propagate_state_from_velo_multi_par(
    const MiniState& UT_state,
    const float qop,
    const int layer,
    const LookingForward::Constants* dev_looking_forward_constants,
    const float* dev_magnet_polarity)
  {
    // center of the magnet
    const MiniState magnet_state = state_at_z(UT_state, dev_looking_forward_constants->zMagnetParams[0]);

    MiniState final_state = magnet_state;

    const float tx_ty_corr =
      LookingForward::tx_ty_corr_multi_par(UT_state, layer / 4, dev_looking_forward_constants, dev_magnet_polarity);

    final_state.tx = tx_ty_corr * qop * (-1.f) * *dev_magnet_polarity + UT_state.tx;

    state_at_z_dzdy_corrected(final_state, dev_looking_forward_constants->Zone_zPos[layer]);
    // final_state = state_at_z(final_state, dev_looking_forward_constants->Zone_zPos[layer]);
    return final_state;
  }

  __device__ inline std::tuple<float, float, float> least_mean_square_y_fit(
    const SciFi::TrackHits& track,
    const unsigned number_of_uv_hits,
    SciFi::ConstHits& scifi_hits,
    const float a1,
    const float b1,
    const float c1,
    const float d_ratio,
    const unsigned event_offset,
    const LookingForward::Constants* dev_looking_forward_constants)
  {
    // Traverse all UV hits
    float y_values[6];
    float z_values[6];
    auto y_mean = 0.f;
    auto z_mean = 0.f;

    for (unsigned j = 0; j < number_of_uv_hits; ++j) {
      const auto hit_index = event_offset + track.hits[track.hitsNum - number_of_uv_hits + j];
      const auto plane = scifi_hits.planeCode(hit_index) / 2;
      const auto z = scifi_hits.z0(hit_index);
      const auto dz = z - LookingForward::z_mid_t;
      const auto predicted_x = c1 + b1 * dz + a1 * dz * dz * (1.f + d_ratio * dz);
      const auto y =
        (predicted_x - scifi_hits.x0(hit_index)) / dev_looking_forward_constants->Zone_dxdy_uvlayers[(plane + 1) % 2];

      y_values[j] = y;
      z_values[j] = z;
      y_mean += y;
      z_mean += z;
    }
    z_mean /= number_of_uv_hits;
    y_mean /= number_of_uv_hits;

    auto nom = 0.f;
    auto denom = 0.f;
    for (unsigned j = 0; j < number_of_uv_hits; ++j) {
      nom += (z_values[j] - z_mean) * (y_values[j] - y_mean);
      denom += (z_values[j] - z_mean) * (z_values[j] - z_mean);
    }
    const auto m = nom / denom;
    const auto b = y_mean - m * z_mean;

    auto lms_fit = 0.f;
    for (unsigned j = 0; j < number_of_uv_hits; ++j) {
      const auto expected_y = b + m * z_values[j];
      lms_fit += (y_values[j] - expected_y) * (y_values[j] - expected_y);
    }

    return {lms_fit / (number_of_uv_hits - 2), b, m};
  }

  __device__ inline float project_y(
    const LookingForward::Constants* dev_looking_forward_constants,
    const MiniState& ut_state,
    const float x_hit,
    const float z_module,
    const int layer)
  {
    const auto Dx = x_hit - (ut_state.x + ut_state.tx * (z_module - ut_state.z));
    const auto tx = ut_state.tx;
    const auto tx2 = ut_state.tx * ut_state.tx;
    const auto tx3 = ut_state.tx * ut_state.tx * ut_state.tx;
    const auto tx4 = ut_state.tx * ut_state.tx * ut_state.tx * ut_state.tx;
    const auto tx5 = ut_state.tx * ut_state.tx * ut_state.tx * ut_state.tx * ut_state.tx;
    const auto ty = ut_state.ty;
    const auto ty3 = ut_state.ty * ut_state.ty * ut_state.ty;
    const auto ty5 = ut_state.ty * ut_state.ty * ut_state.ty * ut_state.ty * ut_state.ty;

    // NOTE :
    // Y expected is evaluated as follow :
    // You assume to know the x position at which the track is passing through via x(Hit), x(Hit) for xLayers is
    // x(measured), on u/v it has to be corrected by stereo angle (done outside this function call) DX = x_hit -
    // (seed_state_projection_at_z_hit) yExpected = C1 *DX + C2 *DX^{2} +  C3*DX^{3} Where C1,C2,C3 = polynomial
    // expansion in tx,ty up to deegre 6.
    // TODO : swap signs in correct places where needed depending on Mag Field.
    // Parameters are computed with Mag-Down, Mag-Up to check.
    const auto C1y_0 = dev_looking_forward_constants->parametrization_layers[18 * layer];
    const auto C1y_1 = dev_looking_forward_constants->parametrization_layers[18 * layer + 1];
    const auto C1y_2 = dev_looking_forward_constants->parametrization_layers[18 * layer + 2];
    const auto C1y_3 = dev_looking_forward_constants->parametrization_layers[18 * layer + 3];
    const auto C1y_4 = dev_looking_forward_constants->parametrization_layers[18 * layer + 4];
    const auto C1y_5 = dev_looking_forward_constants->parametrization_layers[18 * layer + 5];
    const auto C2y_0 = dev_looking_forward_constants->parametrization_layers[18 * layer + 6];
    const auto C2y_1 = dev_looking_forward_constants->parametrization_layers[18 * layer + 7];
    const auto C2y_2 = dev_looking_forward_constants->parametrization_layers[18 * layer + 8];
    const auto C2y_3 = dev_looking_forward_constants->parametrization_layers[18 * layer + 9];
    const auto C2y_4 = dev_looking_forward_constants->parametrization_layers[18 * layer + 10];
    const auto C2y_5 = dev_looking_forward_constants->parametrization_layers[18 * layer + 11];
    const auto C3y_0 = dev_looking_forward_constants->parametrization_layers[18 * layer + 12];
    const auto C3y_1 = dev_looking_forward_constants->parametrization_layers[18 * layer + 13];
    const auto C3y_2 = dev_looking_forward_constants->parametrization_layers[18 * layer + 14];
    const auto C3y_3 = dev_looking_forward_constants->parametrization_layers[18 * layer + 15];
    const auto C3y_4 = dev_looking_forward_constants->parametrization_layers[18 * layer + 16];
    const auto C3y_5 = dev_looking_forward_constants->parametrization_layers[18 * layer + 17];

    const auto C1y =
      C1y_0 * tx * ty + C1y_1 * tx3 * ty + C1y_2 * tx * ty3 + C1y_3 * tx5 * ty + C1y_4 * tx3 * ty3 + C1y_5 * tx * ty5;
    const auto C2y = C2y_0 * ty + C2y_1 * tx2 * ty + C2y_2 * ty3 + C2y_3 * tx4 * ty + C2y_4 * tx2 * ty3 + C2y_5 * ty5;
    const auto C3y =
      C3y_0 * tx * ty + C3y_1 * tx3 * ty + C3y_2 * tx * ty3 + C3y_3 * tx5 * ty + C3y_4 * tx3 * ty3 + C3y_5 * tx * ty5;
    const auto Dy = Dx * C1y + Dx * Dx * C2y + Dx * Dx * Dx * C3y;
    const auto y = ut_state.y + ut_state.ty * (z_module - ut_state.z) + Dy;

    return y;
  }
} // namespace LookingForward
