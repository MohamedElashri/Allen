#include "LookingForwardFindSeedsImpl.cuh"

__device__ void looking_forward_find_seeds_impl(
  const MiniState& velo_ut_state,
  const float ut_qop,
  const uint ut_track_index,
  const SciFi::Hits& hits,
  const SciFi::HitCount& hit_count,
  const int station,
  int* atomics,
  SciFi::TrackHits* scifi_tracks)
{
  std::array<MiniState, 4> proj_state;
  proj_state[0] = propagate_state_from_velo(velo_UT_state, UT_qop, (station - 1) * 4);

  // init the z and yosition for all the layers
  for (int k = 1; k < 4; k++) {
    proj_state[k].z = SciFi::LookingForward::Zone_zPos[(station - 1) * 4 + k];
    proj_state[k].y = y_at_z(velo_UT_state, proj_state[k].z);
  }

  // TODO this could be reused from the propagate_state_from_velo function
  const auto z_mag = SciFi::LookingForward::zMagnetParams[0];
  const auto x_mag = x_at_z(velo_UT_state, z_mag);
  const auto y_mag = y_at_z(velo_UT_state, z_mag);

  if (
    (proj_state[0].x > SciFi::LookingForward::xMin && proj_state[0].x < SciFi::LookingForward::xMax) &&
    (proj_state[0].y > SciFi::LookingForward::yDownMin && proj_state[0].y < SciFi::LookingForward::yUpMax)) {

    const auto dx_plane_0 = dx_calc(UT_qop, window_params);

    const auto layer0_offset_nhits = get_offset_and_n_hits_for_layer(16, hit_count, proj_state[0].y);
    const auto layer0_candidates = find_x_in_window(
      hits,
      std::get<0>(layer0_offset_nhits),
      std::get<1>(layer0_offset_nhits),
      proj_state[0].x - dx_plane_0,
      proj_state[0].x + dx_plane_0);

    // track_candidate.window_stats[8].emplace_back(Window_stat(max_it[0] - min_it[0], x_proj[0], dx_plane_0));
    for (auto hit_layer_0_it = std::get<0>(layer0_candidates); hit_layer_0_it != std::get<1>(layer0_candidates); hit_layer_0_it++) {
      const float projected_slope = (x_mag - hits.x0[hit_layer_0_it]) / (z_mag - proj_state[0].z);
      proj_state[3].x = linear_propagation(hits.x0[hit_layer_0_it], projected_slope, proj_state[3].z - proj_state[0].z);
      // TODO check if this could be done only once, particles close to y 0 may cross the zone
      const auto layer3_offset_nhits = get_offset_and_n_hits_for_layer(22, hit_count, proj_state[3].y);
      const auto layer3_candidates = find_x_in_window(
        hits,
        std::get<0>(layer3_offset_nhits),
        std::get<1>(layer3_offset_nhits),
        proj_state[3].x - window_params.max_window_layer3,
        proj_state[3].x + window_params.max_window_layer3);

      // track_candidate.window_stats[11].emplace_back(Window_stat(max_it[3] - min_it[3], x_proj[3],
      // window_params.max_window_layer3));
      for (auto hit_layer_3_it = std::get<0>(layer3_candidates); hit_layer_3_it != std::get<1>(layer3_candidates); hit_layer_3_it++) {
        const float slope_layer_3_layer_0 =
          (hits.x0[hit_layer_0_it] - hits.x0[hit_layer_3_it]) / (SciFi::LookingForward::dz_x_layers);
        // TODO add layer[2]
        float hit_on_layer_1;
        float hit_on_layer_2;
        proj_state[1].x =
          linear_propagation(hits.x0[hit_layer_0_it], slope_layer_3_layer_0, SciFi::LookingForward::dz_x_u_layers) -
          SciFi::LookingForward::Zone_dxdy[1] * proj_state[1].y;
        const auto layer1_offset_nhits = get_offset_and_n_hits_for_layer(18, hit_count, proj_state[1].y);
        const auto layer1_candidates = find_x_in_window(
          hits,
          std::get<0>(layer1_offset_nhits),
          std::get<1>(layer1_offset_nhits),
          proj_state[1].x - window_params.max_window_layer1,
          proj_state[1].x + window_params.max_window_layer1);

        // track_candidate.window_stats[9].emplace_back(Window_stat(max_it[1] - min_it[1], x_proj[1],
        // window_params.max_window_layer3));

        proj_state[2].x =
          linear_propagation(hits.x0[hit_layer_0_it], slope_layer_3_layer_0, SciFi::LookingForward::dz_x_v_layers) -
          SciFi::LookingForward::Zone_dxdy[2] * proj_state[2].y;

        const auto layer2_offset_nhits = get_offset_and_n_hits_for_layer(20, hit_count, proj_state[2].y);
        const auto layer2_candidates = find_x_in_window(
          hits,
          std::get<0>(layer2_offset_nhits),
          std::get<1>(layer2_offset_nhits),
          proj_state[2].x - window_params.max_window_layer2,
          proj_state[2].x + window_params.max_window_layer2);

        // track_candidate.window_stats[10].emplace_back(Window_stat(max_it[2] - min_it[2], x_proj[2],
        // window_params.max_window_layer2));

        for (auto hit_layer_1_it = std::get<0>(layer1_candidates); hit_layer_1_it != std::get<1>(layer1_candidates); hit_layer_1_it++) {
          float y_layer_1;
          // TODO check i we can reuse the linear propagation
          y_layer_1 = (hits.x0[hit_layer_0_it] +
                       slope_layer_3_layer_0 * (SciFi::LookingForward::dz_x_u_layers) -hits.x0[hit_layer_1_it]) /
                      SciFi::LookingForward::Zone_dxdy[1];
          float y_slope = (y_mag - y_layer_1) / (z_mag - proj_state[1].z);
          for (auto hit_layer_2_it = std::get<0>(layer2_candidates); hit_layer_2_it != std::get<1>(layer2_candidates); hit_layer_2_it++) {
            float distance_layer1;
            float distance_layer2;
            float average_distance;
            float y_layer_2;
            // TODO check i we can reuse the linear propagation
            // y_layer_2 = linear_propagation(y_layer_1, slope_layer_3_layer_0, z_proj[2]-z_proj[1]);
            y_layer_2 = (hits.x0[hit_layer_0_it] +
                         slope_layer_3_layer_0 * (SciFi::LookingForward::dz_x_v_layers) -hits.x0[hit_layer_2_it]) /
                        SciFi::LookingForward::Zone_dxdy[2];
            // distance_layer1 = (hit_on_layer_1 - hit_layer_1_it->x());
            // distance_layer2 = (hit_on_layer_2 - hit_layer_2_it->x());
            distance_layer1 = (hit_on_layer_1 - hits.x0[hit_layer_1_it]);
            distance_layer2 = (hit_on_layer_2 - hits.x0[hit_layer_2_it]);
            // average_distance = (distance_layer1 + distance_layer2)*0.5;
            average_distance = linear_propagation(y_layer_1, y_slope, SciFi::LookingForward::dz_u_v_layers) - y_layer_2;
            // if (std::abs(average_distance) < 0.8){
            // float m,q,chi_2;
            // m = slope_layer_3_layer_0;
            // q = x_coordinates[0] - z_coordinates[0]*m;
            // linear_regression(z_coordinates, x_coordinates, m, q, chi_2);
            // chi_2 = get_chi_2(z_coordinates, x_coordinates, [&m,&q](double x){return m*x+q;});
            // if (chi_2 < window_params.chi2_cut){
            // if (average_distance > -20. && average_distance < 20.){
            SciFi::TrackHits new_track_hits;
            // TODO this should be the update qop using the SciFi hits
            new_track_hits.qop = UT_qop;
            // This is now the chi2 but has the same function
            new_track_hits.quality = average_distance;
            new_track_hits.addHit(hit_layer_0_it);
            new_track_hits.addHit(hit_layer_1_it);
            new_track_hits.addHit(hit_layer_2_it);
            new_track_hits.addHit(hit_layer_3_it);
            track_candidate.emplace_back(new_track_hits);
          }
        }
      }
    }
  }
}
