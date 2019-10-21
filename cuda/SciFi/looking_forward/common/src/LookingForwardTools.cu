#include "LookingForwardTools.cuh"
#include "BinarySearch.cuh"

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

__device__ float LookingForward::dx_calc(const float state_tx, float qop)
{
  float ret_val;
  float qop_window = fabsf(LookingForward::dx_slope * qop + LookingForward::dx_min);
  float tx_window = fabsf(LookingForward::tx_slope * state_tx + LookingForward::tx_min);
  ret_val = LookingForward::tx_weight * tx_window + LookingForward::dx_weight * qop_window;

  // TODO this must be verified
  // ret_val = 1.2e+05*qop + LookingForward::dx_min;
  if (ret_val > LookingForward::max_window_layer0) {
    ret_val = LookingForward::max_window_layer0;
  }

  ret_val = 100.f + 1.4e6f * fabsf(qop);

  return ret_val;
}

__device__ std::tuple<int, int> LookingForward::find_x_in_window(
  const SciFi::Hits& hits,
  const int zone_offset,
  const int num_hits,
  const float value,
  const float margin)
{
  return find_x_in_window(hits, zone_offset, num_hits, value, value, margin);
}

__device__ std::tuple<int, int> LookingForward::find_x_in_window(
  const SciFi::Hits& hits,
  const int zone_offset,
  const int num_hits,
  const float value0,
  const float value1,
  const float margin)
{
  int first_candidate = binary_search_first_candidate(hits.x0 + zone_offset, num_hits, value0, margin);
  int last_candidate = -1;

  if (first_candidate != -1) {
    last_candidate = binary_search_second_candidate(
      hits.x0 + zone_offset + first_candidate, num_hits - first_candidate, value1, margin);
    first_candidate = zone_offset + first_candidate;
    last_candidate += first_candidate;
  }

  return std::tuple<int, int> {first_candidate, last_candidate};
}

__device__ std::tuple<short, short> LookingForward::find_x_in_window(
  const float* hits_x0,
  const int zone_offset,
  const int num_hits,
  const float value,
  const float margin)
{
  short first_candidate = (short) binary_search_first_candidate(hits_x0 + zone_offset, num_hits, value, margin);
  short candidate_size = 0;
  if (first_candidate != -1) {
    candidate_size = (short) binary_search_second_candidate(
      hits_x0 + zone_offset + first_candidate, num_hits - first_candidate, value, margin);
    first_candidate += zone_offset;
  }
  return std::tuple<short, short> {first_candidate, candidate_size};
}

__device__ std::tuple<int, int> LookingForward::get_offset_and_n_hits_for_layer(
  const int first_zone,
  const SciFi::HitCount& scifi_hit_count,
  const float y)
{
  assert(first_zone < (int) (SciFi::Constants::n_zones - 1));
  const auto offset = (y < 0) ? 0 : 1;

  return std::tuple<int, int> {scifi_hit_count.zone_offset(first_zone + offset),
                               scifi_hit_count.zone_number_of_hits(first_zone + offset)};
}

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

__device__ float LookingForward::qop_update_multi_par(
  const MiniState& ut_state,
  const float h0_x,
  const float h0_z,
  const float h1_x,
  const float h1_z,
  const int station,
  const LookingForward::Constants* dev_looking_forward_constants)
{
  const float slope = (h1_x - h0_x) / (h1_z - h0_z);
  return LookingForward::qop_update_multi_par(ut_state, slope, station, dev_looking_forward_constants);
}

__device__ float LookingForward::qop_update_multi_par(
  const MiniState& ut_state,
  const float slope,
  const int station,
  const LookingForward::Constants* dev_looking_forward_constants)
{
  return (slope - ut_state.tx) / LookingForward::tx_ty_corr_multi_par(ut_state, station, dev_looking_forward_constants);
}
