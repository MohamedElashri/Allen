#include "LFCalculateSecondLayerWindowImpl.cuh"

using namespace LookingForward;

__device__ void lf_calculate_second_layer_window_impl(
  MiniState* states_at_z_last_ut_plane,
  const float ut_qop,
  const SciFi::Hits& hits,
  const SciFi::HitCount& hit_count,
  const int first_layer,
  const float* looking_forward_constants,
  const uint relative_ut_track_index,
  const uint local_hit_offset_first_candidate,
  const uint size_first_candidate,
  unsigned short* second_candidate_p,
  const uint total_number_of_candidates)
{
  ProjectionState layer_3_projected_state;
  layer_3_projected_state.z = looking_forward_constants[3];
  layer_3_projected_state.y = y_at_z(states_at_z_last_ut_plane[threadIdx.x], layer_3_projected_state.z);

  const auto layer_1_projected_state_y = y_at_z(states_at_z_last_ut_plane[threadIdx.x], looking_forward_constants[1]);
  const auto layer_2_projected_state_y = y_at_z(states_at_z_last_ut_plane[threadIdx.x], looking_forward_constants[2]);

  const auto x_mag = x_at_z(states_at_z_last_ut_plane[threadIdx.x], looking_forward_constants[4]);
  const auto projected_slope_multiplier = 1.f / (looking_forward_constants[4] - looking_forward_constants[0]);

  for (int i=threadIdx.y; i<size_first_candidate; i+=blockDim.y) {
    const auto global_offset_hit_layer_0 = hit_count.event_offset() + local_hit_offset_first_candidate + i;
    const auto hit_layer_0_x = hits.x0[global_offset_hit_layer_0];

    const auto projected_slope = (x_mag - hit_layer_0_x) * projected_slope_multiplier;
    layer_3_projected_state.x = linear_propagation(hit_layer_0_x, projected_slope, layer_3_projected_state.z - looking_forward_constants[0]);

    const auto layer3_offset_nhits = get_offset_and_n_hits_for_layer(2 * (first_layer+3), hit_count, layer_3_projected_state.y);
    const auto layer3_candidates = find_x_in_window(
      hits,
      std::get<0>(layer3_offset_nhits),
      std::get<1>(layer3_offset_nhits),
      layer_3_projected_state.x,
      LookingForward::max_window_layer3);

    second_candidate_p[i] = relative_ut_track_index;
    second_candidate_p[total_number_of_candidates + i] = local_hit_offset_first_candidate + i;
    second_candidate_p[2*total_number_of_candidates + i] = std::get<0>(layer3_candidates) - hit_count.event_offset();
    second_candidate_p[3*total_number_of_candidates + i] = std::get<1>(layer3_candidates) - std::get<0>(layer3_candidates);
  }

  for (int i=threadIdx.y; i<size_first_candidate; i+=blockDim.y) {
    const auto global_offset_hit_layer_0 = hit_count.event_offset() + local_hit_offset_first_candidate + i;
    const auto hit_layer_0_x = hits.x0[global_offset_hit_layer_0];

    // Find layer1 and layer2 windows here, with min x and max x candidates from before
    const auto slope_layer_3_layer_0_minimum =
      (hits.x0[second_candidate_p[2*total_number_of_candidates + i] + hit_count.event_offset()] - hit_layer_0_x) / (LookingForward::dz_x_layers);
    const auto slope_layer_3_layer_0_maximum =
      (hits.x0[second_candidate_p[2*total_number_of_candidates + i] + second_candidate_p[3*total_number_of_candidates + i] - 1 + hit_count.event_offset()] - hit_layer_0_x) / (LookingForward::dz_x_layers);

    const auto layer_1_projected_state_minimum_x =
      linear_propagation(hit_layer_0_x, slope_layer_3_layer_0_minimum, LookingForward::dz_x_u_layers) -
      looking_forward_constants[5] * layer_1_projected_state_y;
    const auto layer_1_projected_state_maximum_x =
      linear_propagation(hit_layer_0_x, slope_layer_3_layer_0_maximum, LookingForward::dz_x_u_layers) -
      looking_forward_constants[5] * layer_1_projected_state_y;

    const auto layer1_offset_nhits = get_offset_and_n_hits_for_layer(2*(first_layer+1), hit_count, layer_1_projected_state_y);
    const auto layer1_candidates = find_x_in_window(
      hits,
      std::get<0>(layer1_offset_nhits),
      std::get<1>(layer1_offset_nhits),
      layer_1_projected_state_minimum_x,
      layer_1_projected_state_maximum_x,
      LookingForward::max_window_layer1);

    second_candidate_p[4*total_number_of_candidates + i] = std::get<0>(layer1_candidates) - hit_count.event_offset();
    second_candidate_p[5*total_number_of_candidates + i]  = std::get<1>(layer1_candidates) - std::get<0>(layer1_candidates);

    const auto layer_2_projected_state_minimum_x =
      linear_propagation(hit_layer_0_x, slope_layer_3_layer_0_minimum, LookingForward::dz_x_v_layers) -
      looking_forward_constants[6] * layer_2_projected_state_y;
    const auto layer_2_projected_state_maximum_x =
      linear_propagation(hit_layer_0_x, slope_layer_3_layer_0_maximum, LookingForward::dz_x_v_layers) -
      looking_forward_constants[6] * layer_2_projected_state_y;

    const auto layer2_offset_nhits = get_offset_and_n_hits_for_layer(2*(first_layer+2), hit_count, layer_2_projected_state_y);
    const auto layer2_candidates = find_x_in_window(
      hits,
      std::get<0>(layer2_offset_nhits),
      std::get<1>(layer2_offset_nhits),
      layer_2_projected_state_minimum_x,
      layer_2_projected_state_maximum_x,
      LookingForward::max_window_layer2);

    second_candidate_p[6*total_number_of_candidates + i] = std::get<0>(layer2_candidates) - hit_count.event_offset();
    second_candidate_p[7*total_number_of_candidates + i]  = std::get<1>(layer2_candidates) - std::get<0>(layer2_candidates);
  }
}
