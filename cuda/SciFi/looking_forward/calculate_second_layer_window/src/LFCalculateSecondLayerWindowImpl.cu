#include "LFCalculateSecondLayerWindowImpl.cuh"

using namespace LookingForward;

__device__ void lf_calculate_second_layer_window_impl(
  const MiniState& velo_ut_state,
  const float ut_qop,
  const SciFi::Hits& hits,
  const SciFi::HitCount& hit_count,
  const int seeding_first_layer,
  const int seeding_second_layer,
  const LookingForward::Constants* dev_looking_forward_constants,
  const uint relative_ut_track_index,
  const uint local_hit_offset_first_candidate,
  const uint size_first_candidate,
  unsigned short* second_candidate_ut_track,
  unsigned short* second_candidate_first_candidate,
  unsigned short* second_candidate_start,
  unsigned short* second_candidate_size)
{
  MiniState propagated_state =
    propagate_state_from_velo(velo_ut_state, ut_qop, seeding_first_layer, dev_looking_forward_constants);

  // init the z and position
  propagated_state.z = dev_looking_forward_constants->Zone_zPos[seeding_first_layer];
  propagated_state.y = y_at_z(velo_ut_state, propagated_state.z);

  ProjectionState layer_3_projected_state;
  layer_3_projected_state.z = dev_looking_forward_constants->Zone_zPos[seeding_second_layer];
  layer_3_projected_state.y = y_at_z(velo_ut_state, layer_3_projected_state.z);

  const auto z_mag = dev_looking_forward_constants->zMagnetParams[0];
  const auto x_mag = x_at_z(velo_ut_state, z_mag);

  for (int i=threadIdx.y; i<size_first_candidate; i+=blockDim.y) {
    const auto projected_slope = (x_mag - hits.x0[hit_count.event_offset() + local_hit_offset_first_candidate + i]) / (z_mag - propagated_state.z);
    layer_3_projected_state.x = linear_propagation(hits.x0[hit_count.event_offset() + local_hit_offset_first_candidate + i], projected_slope, layer_3_projected_state.z - propagated_state.z);

    const auto layer3_offset_nhits = get_offset_and_n_hits_for_layer(2 * seeding_second_layer, hit_count, layer_3_projected_state.y);
    const auto layer3_candidates = find_x_in_window(
      hits,
      std::get<0>(layer3_offset_nhits),
      std::get<1>(layer3_offset_nhits),
      layer_3_projected_state.x - LookingForward::max_window_layer3,
      layer_3_projected_state.x + LookingForward::max_window_layer3);

    second_candidate_ut_track[i] = relative_ut_track_index;
    second_candidate_first_candidate[i] = local_hit_offset_first_candidate + i;
    second_candidate_start[i] = std::get<0>(layer3_candidates) - hit_count.event_offset();
    second_candidate_size[i] = std::get<1>(layer3_candidates) - std::get<0>(layer3_candidates);
  }
}
