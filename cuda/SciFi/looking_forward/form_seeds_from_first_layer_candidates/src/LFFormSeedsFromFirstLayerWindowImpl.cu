#include "LFCalculateSecondLayerWindowImpl.cuh"

using namespace LookingForward;

// __device__ void insert_candidate(
//   SciFi::TrackCandidate* shared_candidates,
//   const SciFi::TrackCandidate& candidate)
// {
//   int worst_candidate = LookingForward::lf_form_seeds_from_first_layer_window_y_threads;
//   int hitsNum = best_candidates[worst_candidate].hitsNum;
//   float quality = best_candidates[worst_candidate].quality;

//   for (int i=1; i<LookingForward::form_seeds_candidates_per_thread; ++i) {
//     const auto index = i * LookingForward::lf_form_seeds_from_first_layer_window_y_threads;

//     if (best_candidates[index].hitsNum < hitsNum ||
//         (best_candidates[index].hitsNum == hitsNum &&
//         best_candidates[index].quality > quality))
//     {
//       worst_candidate = index;
//       hitsNum = best_candidates[index].hitsNum;
//       quality = best_candidates[index].quality;
//     }
//   }

//   if (candidate.hitsNum > hitsNum ||
//       (candidate.hitsNum == hitsNum &&
//       candidate.quality < quality))
//   {
//     best_candidates[worst_candidate] = candidate;
//   } 
// };

__device__ void lf_form_seeds_from_first_layer_window_impl(
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
  int* track_insert_atomic,
  SciFi::TrackCandidate* scifi_track_candidates)
{
  __shared__ SciFi::TrackCandidate shared_track_candidates [LookingForward::form_seeds_candidates_per_thread * LookingForward::lf_form_seeds_from_first_layer_window_y_threads];
  const auto candidates_found = 0;

  for (int i = threadIdx.x; i < LookingForward::form_seeds_candidates_per_thread * LookingForward::lf_form_seeds_from_first_layer_window_y_threads; i+=blockDim.x) {
    shared_track_candidates[i].quality = 2 * LookingForward::chi2_cut;
    shared_track_candidates[i].hitsNum = 0;
  }

  __syncthreads();

  ProjectionState layer_3_projected_state;
  layer_3_projected_state.z = dev_looking_forward_constants->Zone_zPos[seeding_second_layer];
  layer_3_projected_state.y = y_at_z(velo_ut_state, layer_3_projected_state.z);

  const auto layer_1_projected_state_y = y_at_z(velo_ut_state, dev_looking_forward_constants->Zone_zPos[seeding_second_layer - 2]);
  const auto layer_2_projected_state_y = y_at_z(velo_ut_state, dev_looking_forward_constants->Zone_zPos[seeding_second_layer - 1]);

  const auto z_mag = dev_looking_forward_constants->zMagnetParams[0];
  const auto x_mag = x_at_z(velo_ut_state, z_mag);
  const auto projected_slope_multiplier = 1.f / (z_mag - dev_looking_forward_constants->Zone_zPos[seeding_first_layer]);

  for (int i=threadIdx.y; candidates_found < LookingForward::form_seeds_stop_after_number_of_candidates &&
       i<size_first_candidate; i+=blockDim.y) {
    const auto global_offset_hit_layer_0 = hit_count.event_offset() + local_hit_offset_first_candidate + i;
    const auto hit_layer_0_x = hits.x0[global_offset_hit_layer_0];

    const auto projected_slope = (x_mag - hit_layer_0_x) * projected_slope_multiplier;
    layer_3_projected_state.x = linear_propagation(hit_layer_0_x, projected_slope, layer_3_projected_state.z - dev_looking_forward_constants->Zone_zPos[seeding_first_layer]);

    const auto layer3_offset_nhits = get_offset_and_n_hits_for_layer(2 * seeding_second_layer, hit_count, layer_3_projected_state.y);
    const auto layer3_candidates = find_x_in_window(
      hits,
      std::get<0>(layer3_offset_nhits),
      std::get<1>(layer3_offset_nhits),
      layer_3_projected_state.x - LookingForward::max_window_layer3,
      layer_3_projected_state.x + LookingForward::max_window_layer3);

    // second_candidate_ut_track[i] = relative_ut_track_index;
    // second_candidate_first_candidate[i] = local_hit_offset_first_candidate + i;
    // second_candidate_start[i] = std::get<0>(layer3_candidates) - hit_count.event_offset();
    // second_candidate_size[i] = std::get<1>(layer3_candidates) - std::get<0>(layer3_candidates);

    // Find layer1 and layer2 windows here, with min x and max x candidates from before
    const auto slope_layer_3_layer_0_minimum =
      (hits.x0[std::get<0>(layer3_candidates)] - hit_layer_0_x) / (LookingForward::dz_x_layers);
    const auto slope_layer_3_layer_0_maximum =
      (hits.x0[std::get<1>(layer3_candidates) - 1] - hit_layer_0_x) / (LookingForward::dz_x_layers);

    const auto layer_1_projected_state_minimum_x =
      linear_propagation(hit_layer_0_x, slope_layer_3_layer_0_minimum, LookingForward::dz_x_u_layers) -
      dev_looking_forward_constants->Zone_dxdy[1] * layer_1_projected_state_y;
    const auto layer_1_projected_state_maximum_x =
      linear_propagation(hit_layer_0_x, slope_layer_3_layer_0_maximum, LookingForward::dz_x_u_layers) -
      dev_looking_forward_constants->Zone_dxdy[1] * layer_1_projected_state_y;

    const auto layer1_offset_nhits = get_offset_and_n_hits_for_layer(18, hit_count, layer_1_projected_state_y);
    const auto layer1_candidates = find_x_in_window(
      hits,
      std::get<0>(layer1_offset_nhits),
      std::get<1>(layer1_offset_nhits),
      layer_1_projected_state_minimum_x - LookingForward::max_window_layer1,
      layer_1_projected_state_maximum_x + LookingForward::max_window_layer1);

    // second_candidate_l1_start[i] = std::get<0>(layer1_candidates) - hit_count.event_offset();
    // second_candidate_l1_size[i]  = std::get<1>(layer1_candidates) - std::get<0>(layer1_candidates);

    const auto layer_2_projected_state_minimum_x =
      linear_propagation(hit_layer_0_x, slope_layer_3_layer_0_minimum, LookingForward::dz_x_v_layers) -
      dev_looking_forward_constants->Zone_dxdy[2] * layer_2_projected_state_y;
    const auto layer_2_projected_state_maximum_x =
      linear_propagation(hit_layer_0_x, slope_layer_3_layer_0_maximum, LookingForward::dz_x_v_layers) -
      dev_looking_forward_constants->Zone_dxdy[2] * layer_2_projected_state_y;

    const auto layer2_offset_nhits = get_offset_and_n_hits_for_layer(20, hit_count, layer_2_projected_state_y);
    const auto layer2_candidates = find_x_in_window(
      hits,
      std::get<0>(layer2_offset_nhits),
      std::get<1>(layer2_offset_nhits),
      layer_2_projected_state_minimum_x - LookingForward::max_window_layer2,
      layer_2_projected_state_maximum_x + LookingForward::max_window_layer2);

    // second_candidate_l2_start[i] = std::get<0>(layer2_candidates) - hit_count.event_offset();
    // second_candidate_l2_size[i]  = std::get<1>(layer2_candidates) - std::get<0>(layer2_candidates);
  }

  // __syncthreads();

  // Now, keep the best candidates
  // Find the best <number of threads> candidates
  // Use insertion sort to find the corresponding candidate
  // TODO
}
