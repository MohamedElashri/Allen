#include "LFCalculateFirstLayerWindowImpl.cuh"

using namespace LookingForward;

__device__ void lf_calculate_first_layer_window_impl(
  const MiniState& velo_ut_state,
  const float ut_qop,
  const SciFi::Hits& hits,
  const SciFi::HitCount& hit_count,
  const int seeding_first_layer,
  const LookingForward::Constants* dev_looking_forward_constants,
  uint* first_candidates,
  uint* number_of_candidates,
  MiniState* ut_states,
  const int candidate_index)
{
  MiniState propagated_state =
    propagate_state_from_velo(velo_ut_state, ut_qop, seeding_first_layer, dev_looking_forward_constants);

  // init the z and position
  propagated_state.z = dev_looking_forward_constants->Zone_zPos[seeding_first_layer];
  propagated_state.y = y_at_z(velo_ut_state, propagated_state.z);

  const auto z_mag = dev_looking_forward_constants->zMagnetParams[0];
  const auto x_mag = x_at_z(velo_ut_state, z_mag);
  const auto y_mag = y_at_z(velo_ut_state, z_mag);

  if (
    (propagated_state.x > LookingForward::xMin && propagated_state.x < LookingForward::xMax) &&
    (propagated_state.y > LookingForward::yDownMin && propagated_state.y < LookingForward::yUpMax)) {

    auto dx_plane_0 = dx_calc(propagated_state.tx, ut_qop);
    const auto layer0_offset_nhits =
      get_offset_and_n_hits_for_layer(2 * seeding_first_layer, hit_count, propagated_state.y);

    const auto layer0_candidates = find_x_in_window(
      hits, std::get<0>(layer0_offset_nhits), std::get<1>(layer0_offset_nhits), propagated_state.x, dx_plane_0);

    auto layer0_first_candidate = std::get<0>(layer0_candidates);
    auto layer0_size = std::get<1>(layer0_candidates) - std::get<0>(layer0_candidates);

    if (layer0_size > 10) {
      if (layer0_size > 50) {
        dx_plane_0 *= 0.4f;
      }
      else {
        const auto x = (0.025f * (layer0_size - 10.f));
        dx_plane_0 *= 1.f - 0.6f * x * x;
      }

      const auto layer0_candidates_2 = find_x_in_window(
        hits, std::get<0>(layer0_offset_nhits), std::get<1>(layer0_offset_nhits), propagated_state.x, dx_plane_0);

      layer0_first_candidate = std::get<0>(layer0_candidates_2);
      layer0_size = std::get<1>(layer0_candidates_2) - std::get<0>(layer0_candidates_2);
    }

    first_candidates[candidate_index] = layer0_first_candidate - hit_count.event_offset();
    number_of_candidates[candidate_index] = layer0_size;
    ut_states[candidate_index] = velo_ut_state;
  }
}
