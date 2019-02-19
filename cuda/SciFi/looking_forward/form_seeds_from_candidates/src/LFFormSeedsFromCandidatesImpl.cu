#include "LFFormSeedsFromCandidatesImpl.cuh"

using namespace LookingForward;

__device__ void lf_form_seeds_from_candidates_impl(
  const MiniState& velo_ut_state,
  const float ut_qop,
  const unsigned short rel_ut_track_index,
  const SciFi::Hits& hits,
  const SciFi::HitCount& hit_count,
  const int station,
  const LookingForward::Constants* dev_looking_forward_constants,
  int* track_insert_atomic,
  SciFi::TrackCandidate* scifi_track_candidates,
  const unsigned short first_candidate_index,
  const unsigned short second_candidate_offset,
  const unsigned short second_candidate_size)
{
  const MiniState propagated_state =
    propagate_state_from_velo(velo_ut_state, ut_qop, (station - 1) * 4, dev_looking_forward_constants);

  ProjectionState proj_states[4];
  proj_states[0] = propagated_state;

  // There is an upper limit of the tracks we can add
  bool track_limit_surpassed = false;

  // init the z and yosition for all the layers
  for (int k = 1; k < 4; k++) {
    proj_states[k].z = dev_looking_forward_constants->Zone_zPos[(station - 1) * 4 + k];
    proj_states[k].y = y_at_z(velo_ut_state, proj_states[k].z);
  }

  const auto z_mag = dev_looking_forward_constants->zMagnetParams[0];
  const auto x_mag = x_at_z(velo_ut_state, z_mag);
  const auto y_mag = y_at_z(velo_ut_state, z_mag);

  // Convert to global index
  const auto hit_layer_0 = hit_count.event_offset() + first_candidate_index;

  for (int i=threadIdx.y; !track_limit_surpassed && i<second_candidate_size; i+=blockDim.y) {
    const auto hit_layer_3 = hit_count.event_offset() + second_candidate_offset + i;

    const auto slope_layer_3_layer_0 =
      (hits.x0[hit_layer_3] - hits.x0[hit_layer_0]) / (LookingForward::dz_x_layers);

    proj_states[1].x =
      linear_propagation(hits.x0[hit_layer_0], slope_layer_3_layer_0, LookingForward::dz_x_u_layers) -
      dev_looking_forward_constants->Zone_dxdy[1] * proj_states[1].y;
    const auto layer1_offset_nhits = get_offset_and_n_hits_for_layer(18, hit_count, proj_states[1].y);
    const auto layer1_candidates = find_x_in_window(
      hits,
      std::get<0>(layer1_offset_nhits),
      std::get<1>(layer1_offset_nhits),
      proj_states[1].x - LookingForward::max_window_layer1,
      proj_states[1].x + LookingForward::max_window_layer1);

    const auto hit_layer_1_idx_chi2 = get_best_hit(
      hits,
      slope_layer_3_layer_0,
      layer1_candidates,
      std::make_tuple(proj_states[0].z, hits.x0[hit_layer_0]),
      std::make_tuple(proj_states[3].z, hits.x0[hit_layer_3]),
      proj_states[1].z,
      proj_states[1].y,
      1,
      dev_looking_forward_constants);

    proj_states[2].x =
      linear_propagation(hits.x0[hit_layer_0], slope_layer_3_layer_0, LookingForward::dz_x_v_layers) -
      dev_looking_forward_constants->Zone_dxdy[2] * proj_states[2].y;

    const auto layer2_offset_nhits = get_offset_and_n_hits_for_layer(20, hit_count, proj_states[2].y);
    const auto layer2_candidates = find_x_in_window(
      hits,
      std::get<0>(layer2_offset_nhits),
      std::get<1>(layer2_offset_nhits),
      proj_states[2].x - LookingForward::max_window_layer2,
      proj_states[2].x + LookingForward::max_window_layer2);

    const auto hit_layer_2_idx_chi2 = get_best_hit(
      hits,
      slope_layer_3_layer_0,
      layer2_candidates,
      std::make_tuple(proj_states[0].z, hits.x0[hit_layer_0]),
      std::make_tuple(proj_states[3].z, hits.x0[hit_layer_3]),
      proj_states[2].z,
      proj_states[2].y,
      2,
      dev_looking_forward_constants);

    if ((std::get<0>(hit_layer_1_idx_chi2) != -1) || (std::get<0>(hit_layer_2_idx_chi2) != -1)) {
      const int current_insert_index = atomicAdd(track_insert_atomic, 1);

      // There is an upper limit to the tracks we can insert
      if (current_insert_index < SciFi::Constants::max_track_candidates) {
        auto track_candidate = SciFi::TrackCandidate {
          (short) (hit_layer_0 - hit_count.event_offset()),
          (short) (hit_layer_3 - hit_count.event_offset()),
          rel_ut_track_index,
          ut_qop};

        if (std::get<0>(hit_layer_1_idx_chi2) != -1) {
          track_candidate.add_hit_with_quality(
            (short) (std::get<0>(hit_layer_1_idx_chi2) - hit_count.event_offset()),
            std::get<1>(hit_layer_1_idx_chi2));
        }

        if (std::get<0>(hit_layer_2_idx_chi2) != -1) {
          track_candidate.add_hit_with_quality(
            ((short) std::get<0>(hit_layer_2_idx_chi2) - hit_count.event_offset()),
            std::get<1>(hit_layer_2_idx_chi2));
        }

        scifi_track_candidates[current_insert_index] = track_candidate;
      }
      else {
        track_limit_surpassed = true;
      }
    }
  }
}
