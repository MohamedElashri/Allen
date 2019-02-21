#include "LookingForwardTools.cuh"
#include "BinarySearch.cuh"

// straight line extrapolation of MiniState to other z position
__device__ MiniState LookingForward::state_at_z(const MiniState& state, const float z)
{
  return {state.x + (z - state.z) * state.tx, state.y + (z - state.z) * state.ty, z, state.tx, state.ty};
}

__device__ float LookingForward::x_at_z(const MiniState& state, const float z)
{
  float xf = state.x + (z - state.z) * state.tx;
  return xf;
}

// straight line extrapolation of y to other z position
__device__ float LookingForward::y_at_z(const MiniState& state, const float z)
{
  return state.y + (z - state.z) * state.ty;
}

__device__ float LookingForward::linear_propagation(float x_0, float tx, float dz) { return x_0 + tx * dz; }

__device__ MiniState LookingForward::propagate_state_from_velo(
  const MiniState& UT_state,
  float qop,
  int layer,
  const LookingForward::Constants* dev_looking_forward_constants)
{
  // center of the magnet
  const MiniState magnet_state = state_at_z(UT_state, dev_looking_forward_constants->zMagnetParams[0]);

  MiniState final_state = magnet_state;
  final_state.tx = dev_looking_forward_constants->ds_p_param[layer] * qop + UT_state.tx;

  const auto dp_x_mag =
    (qop > 0) ? dev_looking_forward_constants->dp_x_mag_plus : dev_looking_forward_constants->dp_x_mag_minus;
  const auto dp_y_mag =
    (qop > 0) ? dev_looking_forward_constants->dp_y_mag_plus : dev_looking_forward_constants->dp_y_mag_minus;

  const float x_mag_correction = dp_x_mag[layer][0] + magnet_state.x * dp_x_mag[layer][1] +
                                 magnet_state.x * magnet_state.x * dp_x_mag[layer][2] +
                                 magnet_state.x * magnet_state.x * magnet_state.x * dp_x_mag[layer][3] +
                                 magnet_state.x * magnet_state.x * magnet_state.x * magnet_state.x * dp_x_mag[layer][4];

  const float y_mag_correction =
    dp_y_mag[layer][0] + magnet_state.y * dp_y_mag[layer][1] + magnet_state.y * magnet_state.y * dp_y_mag[layer][2];

  final_state = state_at_z(final_state, dev_looking_forward_constants->Zone_zPos[layer]);
  final_state.x += -y_mag_correction - x_mag_correction;

  return final_state;
}

__device__ float LookingForward::dx_calc(const float state_tx, float qop)
{
  float ret_val;
  float qop_window = std::abs(LookingForward::dx_slope * qop + LookingForward::dx_min);
  float tx_window = std::abs(LookingForward::tx_slope * state_tx + LookingForward::tx_min);
  ret_val = LookingForward::tx_weight * tx_window + LookingForward::dx_weight * qop_window;
  if (ret_val > LookingForward::max_window_layer0) {
    ret_val = LookingForward::max_window_layer0;
  }
  return ret_val;
}

__device__ std::tuple<int, int> LookingForward::find_x_in_window(
  const SciFi::Hits& hits,
  const int zone_offset,
  const int num_hits,
  const float x_min,
  const float x_max)
{
  int first_candidate = binary_search_leftmost(hits.x0 + zone_offset, num_hits, x_min);
  int last_candidate = -1;

  if (first_candidate != -1) {
    last_candidate = binary_search_leftmost(hits.x0 + zone_offset + first_candidate, num_hits - first_candidate, x_max);

    first_candidate = zone_offset + first_candidate;
    last_candidate = last_candidate != -1 ? first_candidate + last_candidate + 1 : -1;
  }

  return {first_candidate, last_candidate};
}

__device__ std::tuple<int, int> LookingForward::get_offset_and_n_hits_for_layer(
  const int first_zone,
  const SciFi::HitCount& scifi_hit_count,
  const float y)
{
  assert(first_zone < SciFi::Constants::n_zones - 1);
  const auto offset = (y < 0) ? 0 : 1;

  return {scifi_hit_count.zone_offset(first_zone + offset), scifi_hit_count.zone_number_of_hits(first_zone + offset)};
}

__device__ std::tuple<int, float> LookingForward::get_best_hit(
  const SciFi::Hits& hits,
  const SciFi::HitCount& hit_count,
  const float m,
  const std::tuple<int, int>& layer_candidates,
  const std::tuple<float, float>& hit_layer_0_z_x,
  const std::tuple<float, float>& hit_layer_3_z_x,
  const float layer_projected_state_z,
  const float layer_projected_state_y,
  const int layer,
  const LookingForward::Constants* dev_looking_forward_constants)
{
  const auto q = std::get<1>(hit_layer_0_z_x) - std::get<0>(hit_layer_0_z_x) * m;
  const auto x_adjustment = layer_projected_state_y * dev_looking_forward_constants->Zone_dxdy[layer];

  int best_index = -1;
  float min_chi2 = LookingForward::chi2_cut;
  for (int i = 0; i < std::get<1>(layer_candidates); i++) {
    const auto hit_index = hit_count.event_offset() + std::get<0>(layer_candidates) + i;
    const auto chi_2 = chi2(
      m,
      q,
      hit_layer_0_z_x,
      std::make_tuple(layer_projected_state_z, hits.x0[hit_index] + x_adjustment),
      hit_layer_3_z_x);

    if (chi_2 < min_chi2) {
      best_index = hit_index;
      min_chi2 = chi_2;
    }
  }

  return {best_index, min_chi2};
}
