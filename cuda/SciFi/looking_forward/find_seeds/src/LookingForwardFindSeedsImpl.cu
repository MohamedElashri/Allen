#include "LookingForwardFindSeedsImpl.cuh"

using namespace LookingForward;

__device__ void looking_forward_find_seeds_impl(
  const MiniState& velo_ut_state,
  const float ut_qop,
  const uint ut_track_index,
  const SciFi::Hits& hits,
  const SciFi::HitCount& hit_count,
  const int station,
  const LookingForward::Constants* dev_looking_forward_constants,
  int* track_insert_atomic,
  SciFi::TrackCandidate* scifi_track_candidates)
{
  const MiniState propagated_state =
    propagate_state_from_velo(velo_ut_state, ut_qop, (station - 1) * 4, dev_looking_forward_constants);

  ProjectionState proj_states[4];
  proj_states[0] = propagated_state;
  const auto proj_state_0_tx = propagated_state.tx;

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

  if (
    (proj_states[0].x > LookingForward::xMin && proj_states[0].x < LookingForward::xMax) &&
    (proj_states[0].y > LookingForward::yDownMin && proj_states[0].y < LookingForward::yUpMax)) {

    const auto dx_plane_0 = dx_calc(proj_state_0_tx, ut_qop);
    const auto layer0_offset_nhits = get_offset_and_n_hits_for_layer(16, hit_count, proj_states[0].y);

    const auto layer0_candidates = find_x_in_window(
      hits,
      std::get<0>(layer0_offset_nhits),
      std::get<1>(layer0_offset_nhits),
      proj_states[0].x,
      dx_plane_0);

    // track_candidate.window_stats[8].emplace_back(Window_stat(max_it[0] - min_it[0], x_proj[0], dx_plane_0));
    for (auto hit_layer_0_it = std::get<0>(layer0_candidates);
         !track_limit_surpassed && hit_layer_0_it != std::get<1>(layer0_candidates);
         hit_layer_0_it++) {
      const auto projected_slope = (x_mag - hits.x0[hit_layer_0_it]) / (z_mag - proj_states[0].z);
      proj_states[3].x =
        linear_propagation(hits.x0[hit_layer_0_it], projected_slope, proj_states[3].z - proj_states[0].z);

      const auto layer3_offset_nhits = get_offset_and_n_hits_for_layer(22, hit_count, proj_states[3].y);
      const auto layer3_candidates = find_x_in_window(
        hits,
        std::get<0>(layer3_offset_nhits),
        std::get<1>(layer3_offset_nhits),
        proj_states[3].x,
        LookingForward::max_window_layer3);

      for (auto hit_layer_3_it = std::get<0>(layer3_candidates);
           !track_limit_surpassed && hit_layer_3_it != std::get<1>(layer3_candidates);
           hit_layer_3_it++) {
        const auto slope_layer_3_layer_0 =
          (hits.x0[hit_layer_3_it] - hits.x0[hit_layer_0_it]) / (LookingForward::dz_x_layers);

        proj_states[1].x =
          linear_propagation(hits.x0[hit_layer_0_it], slope_layer_3_layer_0, LookingForward::dz_x_u_layers) -
          dev_looking_forward_constants->Zone_dxdy[1] * proj_states[1].y;
        const auto layer1_offset_nhits = get_offset_and_n_hits_for_layer(18, hit_count, proj_states[1].y);
        const auto layer1_candidates = find_x_in_window(
          hits,
          std::get<0>(layer1_offset_nhits),
          std::get<1>(layer1_offset_nhits),
          proj_states[1].x,
          LookingForward::max_window_layer1);

        proj_states[2].x =
          linear_propagation(hits.x0[hit_layer_0_it], slope_layer_3_layer_0, LookingForward::dz_x_v_layers) -
          dev_looking_forward_constants->Zone_dxdy[2] * proj_states[2].y;

        const auto layer2_offset_nhits = get_offset_and_n_hits_for_layer(20, hit_count, proj_states[2].y);
        const auto layer2_candidates = find_x_in_window(
          hits,
          std::get<0>(layer2_offset_nhits),
          std::get<1>(layer2_offset_nhits),
          proj_states[2].x,
          LookingForward::max_window_layer2);

        for (auto hit_layer_1_it = std::get<0>(layer1_candidates);
             !track_limit_surpassed && hit_layer_1_it != std::get<1>(layer1_candidates);
             hit_layer_1_it++) {
          // const auto y_layer_1 = (hits.x0[hit_layer_0_it] +
          //                         slope_layer_3_layer_0 * (LookingForward::dz_x_u_layers) -hits.x0[hit_layer_1_it]) /
          //                        dev_looking_forward_constants->Zone_dxdy[1];
          // const auto y_slope = (y_mag - y_layer_1) / (z_mag - proj_states[1].z);
          for (auto hit_layer_2_it = std::get<0>(layer2_candidates);
               !track_limit_surpassed && hit_layer_2_it != std::get<1>(layer2_candidates);
               hit_layer_2_it++) {

            // const auto y_layer_2 = (hits.x0[hit_layer_0_it] +
            //                         slope_layer_3_layer_0 * (LookingForward::dz_x_v_layers) -hits.x0[hit_layer_2_it]) /
            //                        dev_looking_forward_constants->Zone_dxdy[2];

            // Calculate chi2 of found track
            const auto m = slope_layer_3_layer_0;
            const auto q = hits.x0[hit_layer_0_it] - proj_states[0].z * m;

            const auto chi_2 = chi2(
              m,
              q,
              std::make_tuple(proj_states[0].z, hits.x0[hit_layer_0_it]),
              std::make_tuple(proj_states[1].z, hits.x0[hit_layer_1_it] + proj_states[1].y * dev_looking_forward_constants->Zone_dxdy[1]),
              std::make_tuple(proj_states[2].z, hits.x0[hit_layer_2_it] + proj_states[2].y * dev_looking_forward_constants->Zone_dxdy[2]),
              std::make_tuple(proj_states[3].z, hits.x0[hit_layer_3_it])
            );

            if (chi_2 < LookingForward::chi2_cut) {
              // const auto average_distance = linear_propagation(y_layer_1, y_slope, LookingForward::dz_u_v_layers) -
              // y_layer_2;
              const int current_insert_index = atomicAdd(track_insert_atomic, 1);

              // There is an upper limit to the tracks we can insert
              if (current_insert_index < SciFi::Constants::max_track_candidates) {
                // scifi_track_candidates[current_insert_index] = SciFi::TrackCandidate {
                //   hit_layer_0_it, hit_layer_1_it, hit_layer_2_it, hit_layer_3_it, ut_track_index, ut_qop, chi_2};
              }
              else {
                track_limit_surpassed = true;
              }
            }
          }
        }
      }
    }
  }
}
