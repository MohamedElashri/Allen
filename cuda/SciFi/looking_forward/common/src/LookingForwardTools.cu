#include "LookingForwardTools.cuh"
#include "BinarySearch.cuh"

__device__ float LookingForward::tx_ty_corr_multi_par(
  const MiniState& ut_state,
  const int station,
  const LookingForward::Constants* dev_looking_forward_constants)
{
  float tx_ty_corr = 0;
  const float tx_pow[5] = {1,
                           ut_state.tx,
                           ut_state.tx * ut_state.tx,
                           ut_state.tx * ut_state.tx * ut_state.tx,
                           ut_state.tx * ut_state.tx * ut_state.tx * ut_state.tx};

  const float ty_pow[5] = {1,
                           ut_state.ty,
                           ut_state.ty * ut_state.ty,
                           ut_state.ty * ut_state.ty * ut_state.ty,
                           ut_state.ty * ut_state.ty * ut_state.ty * ut_state.ty};

  for (int i = 0; i < 5; i++) {
    for (int j = 0; j < 5; j++) {
      tx_ty_corr += dev_looking_forward_constants->ds_multi_param[station * 5 * 5 + i * 5 + j] * tx_pow[i] * ty_pow[j];
    }
  }

  return tx_ty_corr;
}

__device__ MiniState LookingForward::propagate_state_from_velo_multi_par(
  const MiniState& UT_state,
  const float qop,
  const int layer,
  const LookingForward::Constants* dev_looking_forward_constants)
{
  // center of the magnet
  const MiniState magnet_state = state_at_z(UT_state, dev_looking_forward_constants->zMagnetParams[0]);

  MiniState final_state = magnet_state;

  const float tx_ty_corr = LookingForward::tx_ty_corr_multi_par(UT_state, layer / 4, dev_looking_forward_constants);

  final_state.tx = tx_ty_corr * qop + UT_state.tx;

  state_at_z_dzdy_corrected(final_state, dev_looking_forward_constants->Zone_zPos[layer]);
  // final_state = state_at_z(final_state, dev_looking_forward_constants->Zone_zPos[layer]);
  return final_state;
}

__device__ float LookingForward::propagate_x_from_velo_multi_par(
  const MiniState& UT_state,
  const float qop,
  const int layer,
  const LookingForward::Constants* dev_looking_forward_constants)
{
  const float tx_ty_corr = LookingForward::tx_ty_corr_multi_par(UT_state, layer / 4, dev_looking_forward_constants);

  const float final_tx = tx_ty_corr * qop + UT_state.tx;

  // get x and y at center of magnet
  const auto magnet_x =
    linear_propagation(UT_state.x, UT_state.tx, dev_looking_forward_constants->zMagnetParams[0] - UT_state.z);

  return linear_propagation(
    magnet_x, final_tx, dev_looking_forward_constants->Zone_zPos[layer] - LookingForward::z_magnet);
}

__device__ std::tuple<float, float, float> LookingForward::lms_y_fit(
  const SciFi::TrackHits& track,
  const uint number_of_uv_hits,
  const SciFi::Hits& scifi_hits,
  const float a1,
  const float b1,
  const float c1,
  const float d_ratio,
  const uint event_offset,
  const LookingForward::Constants* dev_looking_forward_constants)
{
  // Traverse all UV hits
  float y_values[6];
  float z_values[6];
  auto y_mean = 0.f;
  auto z_mean = 0.f;

  for (uint j = 0; j < number_of_uv_hits; ++j) {
    const auto hit_index = event_offset + track.hits[track.hitsNum - number_of_uv_hits + j];
    const auto plane = scifi_hits.planeCode(hit_index) / 2;
    const auto z = scifi_hits.z0[hit_index];
    const auto dz = z - LookingForward::z_mid_t;
    const auto predicted_x = c1 + b1 * dz + a1 * dz * dz * (1.f + d_ratio * dz);
    const auto y =
      (predicted_x - scifi_hits.x0[hit_index]) / dev_looking_forward_constants->Zone_dxdy_uvlayers[(plane + 1) % 2];

    y_values[j] = y;
    z_values[j] = z;
    y_mean += y;
    z_mean += z;
  }
  z_mean /= number_of_uv_hits;
  y_mean /= number_of_uv_hits;

  auto nom = 0.f;
  auto denom = 0.f;
  for (uint j = 0; j < number_of_uv_hits; ++j) {
    nom += (z_values[j] - z_mean) * (y_values[j] - y_mean);
    denom += (z_values[j] - z_mean) * (z_values[j] - z_mean);
  }
  const auto m = nom / denom;
  const auto b = y_mean - m * z_mean;

  auto lms_fit = 0.f;
  for (uint j = 0; j < number_of_uv_hits; ++j) {
    const auto expected_y = b + m * z_values[j];
    lms_fit += (y_values[j] - expected_y) * (y_values[j] - expected_y);
  }

  return {lms_fit / (number_of_uv_hits - 2), b, m};
}
