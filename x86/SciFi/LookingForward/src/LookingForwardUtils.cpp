#include "LookingForwardUtils.h"

float x_at_z(const MiniState& state, const float z)
{
  float xf = state.x + (z - state.z) * state.tx;
  return xf;
}

float linear_propagation(float x_0, float tx, float dz) { return x_0 + tx * dz; }

float scifi_propagation(const float x_0, const float tx, const float qop, const float dz)
{
  return linear_propagation(x_0, tx, dz) + SciFi::LookingForward::forward_param * qop * dz * dz;
}

float qop_update(
  const MiniState& UT_state,
  const float h0_x,
  const float h1_x,
  const float h0_z,
  const float h1_z,
  int layer)
{
  const float slope = (h1_x - h0_x) / std::abs(h1_z - h0_z);
  return (slope - UT_state.tx) / SciFi::LookingForward::ds_p_param[layer];
}

MiniState propagate_state_from_velo(const MiniState& UT_state, float qop, int layer)
{
  MiniState final_state;
  MiniState magnet_state;

  float x_mag_correction;
  float y_mag_correction;

  // center of the magnet
  magnet_state = state_at_z(UT_state, SciFi::LookingForward::zMagnetParams[0]);

  final_state = magnet_state;

  final_state.tx = SciFi::LookingForward::ds_p_param[layer] * qop + UT_state.tx;

  // TODO this could be done withoud branching
  if (qop > 0) {
    y_mag_correction = SciFi::LookingForward::dp_y_mag_plus[layer][0] +
                       magnet_state.y * SciFi::LookingForward::dp_y_mag_plus[layer][1] +
                       magnet_state.y * magnet_state.y * SciFi::LookingForward::dp_y_mag_plus[layer][2];
    // SciFi::LookingForward::dp_plus_offset[layer];

    x_mag_correction =
      SciFi::LookingForward::dp_x_mag_plus[layer][0] + magnet_state.x * SciFi::LookingForward::dp_x_mag_plus[layer][1] +
      magnet_state.x * magnet_state.x * SciFi::LookingForward::dp_x_mag_plus[layer][2] +
      magnet_state.x * magnet_state.x * magnet_state.x * SciFi::LookingForward::dp_x_mag_plus[layer][3] +
      magnet_state.x * magnet_state.x * magnet_state.x * magnet_state.x *
        SciFi::LookingForward::dp_x_mag_plus[layer][4];
  }
  else {
    y_mag_correction = SciFi::LookingForward::dp_y_mag_minus[layer][0] +
                       magnet_state.y * SciFi::LookingForward::dp_y_mag_minus[layer][1] +
                       magnet_state.y * magnet_state.y * SciFi::LookingForward::dp_y_mag_minus[layer][2]; //+
    // SciFi::LookingForward::dp_minus_offset[layer];

    x_mag_correction =
      SciFi::LookingForward::dp_x_mag_minus[layer][0] +
      magnet_state.x * SciFi::LookingForward::dp_x_mag_minus[layer][1] +
      magnet_state.x * magnet_state.x * SciFi::LookingForward::dp_x_mag_minus[layer][2] +
      magnet_state.x * magnet_state.x * magnet_state.x * SciFi::LookingForward::dp_x_mag_minus[layer][3] +
      magnet_state.x * magnet_state.x * magnet_state.x * magnet_state.x *
        SciFi::LookingForward::dp_x_mag_minus[layer][4];
  }
  final_state = state_at_z(final_state, SciFi::LookingForward::Zone_zPos[layer]);
  final_state.x += -y_mag_correction - x_mag_correction;

  return final_state;
}

std::tuple<int, int> get_u_or_v_layer_candidates(
  const SciFi::Hits& hits,
  const SciFi::HitCount& hit_count,
  const int hit_layer_0_idx,
  const float slope_layer_3_layer_0_minx,
  const float slope_layer_3_layer_0_maxx,
  const MiniState& proj_state,
  const float dxdy,
  const int zone,
  const float dz,
  std::vector<Window_stat>& window_stats,
  const float max_window)
{

  const auto proj_state_minx =
    linear_propagation(hits.x0[hit_layer_0_idx], slope_layer_3_layer_0_minx, dz) - dxdy * proj_state.y;
  const auto proj_state_maxx =
    linear_propagation(hits.x0[hit_layer_0_idx], slope_layer_3_layer_0_maxx, dz) - dxdy * proj_state.y;

  const auto layer_offset_nhits = get_offset_and_n_hits_for_layer(zone, hit_count, proj_state.y);
  const auto layer_candidates = find_x_in_window(
    hits,
    std::get<0>(layer_offset_nhits),
    std::get<1>(layer_offset_nhits),
    proj_state_minx,
    proj_state_maxx,
    max_window);

  window_stats.emplace_back(
    Window_stat(Window_stat(std::get<1>(layer_candidates) - std::get<0>(layer_candidates), proj_state.x, max_window)));

  return layer_candidates;
}

std::tuple<int, float> select_best_u_or_v_hit(
  const float slope_layer_3_layer_0,
  const int hit_layer_0_idx,
  const int hit_layer_3_idx,
  std::array<MiniState, 4>& proj_state,
  const int layer,
  const SciFi::Hits& hits,
  const float dz,
  const float dxdy,
  const std::tuple<int, int>& layer_candidates,
  const SciFiWindowsParams& window_params)
{
  proj_state[layer].x =
    linear_propagation(hits.x0[hit_layer_0_idx], slope_layer_3_layer_0, dz) - dxdy * proj_state[layer].y;

  return get_best_hit(
    hits, hit_layer_0_idx, hit_layer_3_idx, slope_layer_3_layer_0, layer_candidates, proj_state, window_params, layer);
}

// the vector of TrackHits is there just for debugging in the real implementation this will be a C-like array
bool select_hits(
  const MiniState& velo_UT_state,
  float UT_qop,
  unsigned int UT_track_index,
  const SciFi::Hits& hits,
  const SciFi::HitCount& hit_count,
  const int station,
  std::vector<SciFi::TrackHits>& track_candidate,
  std::array<std::vector<Window_stat>, 4>& window_stats,
  const SciFiWindowsParams& window_params)
{
  bool ret_val = false;
  std::array<MiniState, 4> proj_state;
  float x_mag, y_mag, z_mag;
  float dx_plane_0;
  float projected_slope;
  int found_candidates = 0;

  // // Number of candidates maximum of each ut track
  // // Only the best will be kept
  // std::array<SciFi::TrackHits, 20> best_candidates;
  // for (int i = 0; i < best_candidates.size(); ++i) {
  //   best_candidates[i].quality = 2 * window_params.chi2_cut;
  //   best_candidates[i].hitsNum = 0;
  // }

  const auto insert_candidate = [](const SciFi::TrackHits& candidate, auto& best_candidates) {
    int worst_candidate = 0;
    int hitsNum = best_candidates[worst_candidate].hitsNum;
    float quality = best_candidates[worst_candidate].quality;

    for (int i = 1; i < best_candidates.size(); ++i) {
      if (
        best_candidates[i].hitsNum < hitsNum ||
        (best_candidates[i].hitsNum == hitsNum && best_candidates[i].quality > quality)) {
        worst_candidate = i;
        hitsNum = best_candidates[i].hitsNum;
        quality = best_candidates[i].quality;
      }
    }

    if (candidate.hitsNum > hitsNum || (candidate.hitsNum == hitsNum && candidate.quality < quality)) {
      best_candidates[worst_candidate] = candidate;
    }
  };

  proj_state[0] = propagate_state_from_velo(velo_UT_state, UT_qop, (station - 1) * 4);

  // init the z and yosition for all the layers
  for (int k = 1; k < 4; k++) {
    proj_state[k].z = SciFi::LookingForward::Zone_zPos[(station - 1) * 4 + k];
    proj_state[k].y = y_at_z(velo_UT_state, proj_state[k].z);
  }

  // TODO this could be reused from the propagate_state_from_velo function
  z_mag = SciFi::LookingForward::zMagnetParams[0];
  x_mag = x_at_z(velo_UT_state, z_mag);
  y_mag = y_at_z(velo_UT_state, z_mag);

  if (
    (proj_state[0].x > SciFi::LookingForward::xMin && proj_state[0].x < SciFi::LookingForward::xMax) &&
    (proj_state[0].y > SciFi::LookingForward::yDownMin && proj_state[0].y < SciFi::LookingForward::yUpMax)) {

    dx_plane_0 = dx_calc(proj_state[0], UT_qop, window_params);

    const auto layer0_offset_nhits = get_offset_and_n_hits_for_layer(16, hit_count, proj_state[0].y);

    auto layer0_candidates = find_x_in_window(
      hits, std::get<0>(layer0_offset_nhits), std::get<1>(layer0_offset_nhits), proj_state[0].x, dx_plane_0);

    // No correction: 859422, 51.2702%
    // 10-40 linear: 608419, 49.0444%
    // 10-40 quadratic: 658121, 49.8758%
    // 10-50 quadratic, 0.4f: 693444, 50.1082%
    // step at 20, 0.8f: 733594, 50.3085%
    // step at 20, 0.7f: 670149, 49.5672%

    // 10-50 quadratic, 0.4f: 72.34%
    // 10-50 quadratic, 0.5f: 72.83%

    const auto number_of_l0_candidates = std::get<1>(layer0_candidates) - std::get<0>(layer0_candidates);
    if (number_of_l0_candidates > 10) {
      if (number_of_l0_candidates > 50) {
        dx_plane_0 *= 0.4f;
      }
      else {
        const auto x = (0.025f * (number_of_l0_candidates - 10.f));
        dx_plane_0 *= 1.f - 0.6f * x * x;
      }

      layer0_candidates = find_x_in_window(
        hits, std::get<0>(layer0_offset_nhits), std::get<1>(layer0_offset_nhits), proj_state[0].x, dx_plane_0);
    }

    window_stats[0].emplace_back(
      Window_stat(std::get<1>(layer0_candidates) - std::get<0>(layer0_candidates), proj_state[0].x, dx_plane_0));
    for (auto hit_layer_0_idx = std::get<0>(layer0_candidates); hit_layer_0_idx != std::get<1>(layer0_candidates);
         hit_layer_0_idx++) {
      projected_slope = (x_mag - hits.x0[hit_layer_0_idx]) / (z_mag - proj_state[0].z);
      proj_state[3].x =
        linear_propagation(hits.x0[hit_layer_0_idx], projected_slope, proj_state[3].z - proj_state[0].z);
      // TODO check if this could be done only once, particles close to y 0 may cross the zone
      const auto layer3_offset_nhits = get_offset_and_n_hits_for_layer(22, hit_count, proj_state[3].y);

      const auto layer3_candidates = find_x_in_window(
        hits,
        std::get<0>(layer3_offset_nhits),
        std::get<1>(layer3_offset_nhits),
        proj_state[3].x,
        window_params.max_window_layer3);

      window_stats[3].emplace_back(Window_stat(Window_stat(
        std::get<1>(layer3_candidates) - std::get<0>(layer3_candidates),
        proj_state[3].x,
        window_params.max_window_layer3)));

      if (std::get<0>(layer3_candidates) != -1) {

        const float slope_layer_3_layer_0_minx =
          (hits.x0[std::get<0>(layer3_candidates)] - hits.x0[hit_layer_0_idx]) / (SciFi::LookingForward::dz_x_layers);
        const float slope_layer_3_layer_0_maxx =
          (hits.x0[std::get<1>(layer3_candidates) - 1] - hits.x0[hit_layer_0_idx]) /
          (SciFi::LookingForward::dz_x_layers);

        const auto layer1_candidates = get_u_or_v_layer_candidates(
          hits,
          hit_count,
          hit_layer_0_idx,
          slope_layer_3_layer_0_minx,
          slope_layer_3_layer_0_maxx,
          proj_state[1],
          SciFi::LookingForward::Zone_dxdy[1],
          18,
          SciFi::LookingForward::dz_x_u_layers,
          window_stats[1],
          window_params.max_window_layer1);

        const auto layer2_candidates = get_u_or_v_layer_candidates(
          hits,
          hit_count,
          hit_layer_0_idx,
          slope_layer_3_layer_0_minx,
          slope_layer_3_layer_0_maxx,
          proj_state[2],
          SciFi::LookingForward::Zone_dxdy[2],
          20,
          SciFi::LookingForward::dz_x_v_layers,
          window_stats[2],
          window_params.max_window_layer2);

        std::array<SciFi::TrackHits, 1> best_candidates;
        for (int i = 0; i < best_candidates.size(); ++i) {
          best_candidates[i].quality = 2 * window_params.chi2_cut;
          best_candidates[i].hitsNum = 0;
        }

        const auto number_of_l3_candidates = std::get<1>(layer3_candidates) - std::get<0>(layer3_candidates);
        for (int hit_layer_3_rel_idx = 0; hit_layer_3_rel_idx < window_params.maximum_iteration_l3_window &&
                                          hit_layer_3_rel_idx < number_of_l3_candidates;
             ++hit_layer_3_rel_idx) {
          const auto hit_layer_3_idx = std::get<0>(layer3_candidates) + hit_layer_3_rel_idx;

          const float slope_layer_3_layer_0 =
            (hits.x0[hit_layer_3_idx] - hits.x0[hit_layer_0_idx]) / (SciFi::LookingForward::dz_x_layers);

          auto hit_layer_1_idx_chi2 = select_best_u_or_v_hit(
            slope_layer_3_layer_0,
            hit_layer_0_idx,
            hit_layer_3_idx,
            proj_state,
            1,
            hits,
            SciFi::LookingForward::dz_x_u_layers,
            SciFi::LookingForward::Zone_dxdy[1],
            layer1_candidates,
            window_params);

          auto hit_layer_2_idx_chi2 = select_best_u_or_v_hit(
            slope_layer_3_layer_0,
            hit_layer_0_idx,
            hit_layer_3_idx,
            proj_state,
            2,
            hits,
            SciFi::LookingForward::dz_x_v_layers,
            SciFi::LookingForward::Zone_dxdy[2],
            layer2_candidates,
            window_params);

          if ((std::get<0>(hit_layer_1_idx_chi2) != -1) || (std::get<0>(hit_layer_2_idx_chi2) != -1)) {
            SciFi::TrackHits new_track_hits;
            float updated_qop = qop_update(
              velo_UT_state,
              hits.x0[hit_layer_0_idx],
              hits.x0[hit_layer_3_idx],
              SciFi::LookingForward::Zone_zPos[8],
              SciFi::LookingForward::Zone_zPos[11],
              8);

            new_track_hits.ut_track_index = UT_track_index;
            new_track_hits.hitsNum = 0;
            new_track_hits.qop = updated_qop;
            new_track_hits.quality = 0;
            new_track_hits.add_hit((uint16_t)(hit_layer_0_idx - hit_count.event_offset()));
            new_track_hits.add_hit((uint16_t)(hit_layer_3_idx - hit_count.event_offset()));

            if (std::get<0>(hit_layer_1_idx_chi2) != -1) {
              new_track_hits.add_hit_with_quality(
                (uint16_t)(std::get<0>(hit_layer_1_idx_chi2) - hit_count.event_offset()),
                std::get<1>(hit_layer_1_idx_chi2));
            }

            if (std::get<0>(hit_layer_2_idx_chi2) != -1) {
              new_track_hits.add_hit_with_quality(
                (uint16_t)(std::get<0>(hit_layer_2_idx_chi2) - hit_count.event_offset()),
                std::get<1>(hit_layer_2_idx_chi2));
            }
            ret_val = true;

            // const int worst_candidate = (best_candidates[0].hitsNum > best_candidates[1].hitsNum) ||
            //                                 ((best_candidates[0].hitsNum == best_candidates[1].hitsNum) &&
            //                                  best_candidates[0].quality < best_candidates[1].quality) ?
            //                               1 :
            //                               0;

            if (
              new_track_hits.hitsNum > best_candidates[0].hitsNum ||
              (new_track_hits.hitsNum == best_candidates[0].hitsNum &&
               new_track_hits.quality < best_candidates[0].quality)) {

              best_candidates[0] = new_track_hits;
            }

            // insert_candidate(new_track_hits, best_candidates);
            // found_candidates++;
            //
            // track_candidate.emplace_back(new_track_hits);
          }
        }

        for (int i = 0; i < best_candidates.size(); ++i) {
          if (best_candidates[i].hitsNum > 2) {
            // printf("%i, %i, %i, %i\n", best_candidates[i].hits[0],
            //   best_candidates[i].hits[1], best_candidates[i].hits[2], best_candidates[i].hits[3]);

            track_candidate.push_back(best_candidates[i]);
          }
        }

        // if (best_candidate.hitsNum > 2) {
        //   track_candidate.emplace_back(best_candidate);
        // }
      }
    }
  }

  // for (int i = 0; i < best_candidates.size(); ++i) {
  //   if (best_candidates[i].hitsNum > 0) {
  //     track_candidate.push_back(best_candidates[i]);
  //   }
  // }

  return ret_val;
}

void propagate_candidates(
  const int layer,
  const SciFi::Hits& hits,
  const SciFi::HitCount& hit_count,
  const MiniState& velo_UT_state,
  const std::vector<SciFi::TrackHits>& candidates,
  std::vector<bool>& candidates_extrapolated,
  std::vector<SciFi::TrackHits>& tracks,
  const SciFiWindowsParams& window_params)
{
  for (int i = 0; i < candidates.size(); ++i) {
    if (!candidates_extrapolated[i]) {
      candidates_extrapolated[i] = single_candidate_propagation(
        layer,
        hits,
        hit_count,
        velo_UT_state,
        candidates[i],
        tracks,
        window_params.extrapolation_stddev[layer],
        window_params.chi2_extrap_mean[layer],
        window_params.chi2_extrap_stddev[layer]);
    }
  }
}

void propagate_tracks(
  const int layer,
  const SciFi::Hits& hits,
  const SciFi::HitCount& hit_count,
  const MiniState& velo_UT_state,
  std::vector<SciFi::TrackHits>& tracks,
  const SciFiWindowsParams& window_params)
{
  for (int i = 0; i < tracks.size(); ++i) {
    single_track_propagation(
      layer,
      hits,
      hit_count,
      velo_UT_state,
      tracks[i],
      window_params.extrapolation_stddev[layer],
      window_params.chi2_extrap_mean[layer],
      window_params.chi2_extrap_stddev[layer]);
  }
}

bool single_candidate_propagation(
  const int layer,
  const SciFi::Hits& hits,
  const SciFi::HitCount& hit_count,
  const MiniState& velo_UT_state,
  const SciFi::TrackHits& candidate,
  std::vector<SciFi::TrackHits>& tracks,
  const float extrapolation_stddev,
  const float chi2_extrap_mean,
  const float chi2_extrap_stddev)
{
  bool found_candidates_in_layer = false;
  const auto projection_y = y_at_z(velo_UT_state, SciFi::LookingForward::Zone_zPos[layer]);

  // do the propagation
  const auto x_at_layer_8 = hits.x0[hit_count.event_offset() + candidate.hits[0]];
  const auto reco_slope = (hits.x0[hit_count.event_offset() + candidate.hits[1]] - x_at_layer_8) /
                          (SciFi::LookingForward::Zone_zPos[11] - SciFi::LookingForward::Zone_zPos[8]);

  const auto projection_x = scifi_propagation(
                              x_at_layer_8,
                              reco_slope,
                              candidate.qop,
                              SciFi::LookingForward::Zone_zPos[layer] - SciFi::LookingForward::Zone_zPos[8]) -
                            SciFi::LookingForward::Zone_dxdy[(layer % 4)] * projection_y;

  const auto layer_offset_nhits = get_offset_and_n_hits_for_layer(2 * layer, hit_count, projection_y);

  const auto layer_candidates = find_x_in_window(
    hits, std::get<0>(layer_offset_nhits), std::get<1>(layer_offset_nhits), projection_x, 3 * extrapolation_stddev);

  // Pick the best, according to chi2
  int best_idx = -1;
  float best_chi2 = chi2_extrap_mean + 2.f * chi2_extrap_stddev;

  // We need a new lambda to compare in chi2
  const auto chi2_fn = [&x_at_layer_8, &reco_slope, &candidate](const float z) {
    return scifi_propagation(x_at_layer_8, reco_slope, candidate.qop, z - SciFi::LookingForward::Zone_zPos[8]);
  };

  std::vector<float> x_coordinates {x_at_layer_8, hits.x0[hit_count.event_offset() + candidate.hits[1]], 0.f};

  std::vector<float> z_coordinates {
    SciFi::LookingForward::Zone_zPos[8], SciFi::LookingForward::Zone_zPos[11], SciFi::LookingForward::Zone_zPos[layer]};

  for (auto hit_index = std::get<0>(layer_candidates); hit_index != std::get<1>(layer_candidates); hit_index++) {
    x_coordinates[2] = hits.x0[hit_index] + projection_y * SciFi::LookingForward::Zone_dxdy[(layer % 4)];
    const auto chi2 = get_chi_2(z_coordinates, x_coordinates, chi2_fn);

    if (chi2 < best_chi2) {
      best_chi2 = chi2;
      best_idx = hit_index;
    }
  }

  if (best_idx != -1) {
    found_candidates_in_layer = true;
    SciFi::TrackHits track = candidate;
    track.add_hit_with_quality((uint16_t)(best_idx - hit_count.event_offset()), best_chi2);
    tracks.emplace_back(track);
  }

  return found_candidates_in_layer;
}

void single_track_propagation(
  const int layer,
  const SciFi::Hits& hits,
  const SciFi::HitCount& hit_count,
  const MiniState& velo_UT_state,
  SciFi::TrackHits& track,
  const float extrapolation_stddev,
  const float chi2_extrap_mean,
  const float chi2_extrap_stddev)
{
  const auto projection_y = y_at_z(velo_UT_state, SciFi::LookingForward::Zone_zPos[layer]);

  // do the propagation
  const auto x_at_layer_8 = hits.x0[hit_count.event_offset() + track.hits[0]];
  const auto reco_slope = (hits.x0[hit_count.event_offset() + track.hits[1]] - x_at_layer_8) /
                          (SciFi::LookingForward::Zone_zPos[11] - SciFi::LookingForward::Zone_zPos[8]);

  const auto projection_x = scifi_propagation(
                              x_at_layer_8,
                              reco_slope,
                              track.qop,
                              SciFi::LookingForward::Zone_zPos[layer] - SciFi::LookingForward::Zone_zPos[8]) -
                            SciFi::LookingForward::Zone_dxdy[(layer % 4)] * projection_y;

  const auto layer_offset_nhits = get_offset_and_n_hits_for_layer(2 * layer, hit_count, projection_y);

  const auto layer_candidates = find_x_in_window(
    hits, std::get<0>(layer_offset_nhits), std::get<1>(layer_offset_nhits), projection_x, 3 * extrapolation_stddev);

  // Pick the best, according to chi2
  int best_idx = -1;
  float best_chi2 = chi2_extrap_mean + 2.f * chi2_extrap_stddev;

  // We need a new lambda to compare in chi2
  const auto chi2_fn = [&x_at_layer_8, &reco_slope, &track](const float z) {
    return scifi_propagation(x_at_layer_8, reco_slope, track.qop, z - SciFi::LookingForward::Zone_zPos[8]);
  };

  std::vector<float> x_coordinates {x_at_layer_8, hits.x0[hit_count.event_offset() + track.hits[1]], 0.f};

  std::vector<float> z_coordinates {
    SciFi::LookingForward::Zone_zPos[8], SciFi::LookingForward::Zone_zPos[11], SciFi::LookingForward::Zone_zPos[layer]};

  for (auto hit_index = std::get<0>(layer_candidates); hit_index != std::get<1>(layer_candidates); hit_index++) {
    x_coordinates[2] = hits.x0[hit_index] + projection_y * SciFi::LookingForward::Zone_dxdy[(layer % 4)];
    const auto chi2 = get_chi_2(z_coordinates, x_coordinates, chi2_fn);

    if (chi2 < best_chi2) {
      best_chi2 = chi2;
      best_idx = hit_index;
    }
  }

  if (best_idx != -1) {
    track.add_hit_with_quality((uint16_t)(best_idx - hit_count.event_offset()), best_chi2);
  }
}

float dx_calc(const MiniState& state, float qop, const SciFiWindowsParams& window_params)
{
  float ret_val;
  float qop_window = std::abs(window_params.dx_slope * qop + window_params.dx_min);
  float tx_window = std::abs(window_params.tx_slope * state.tx + window_params.tx_min);

  // info_cout << "QOP and tx windows: " << qop_window << ", " << tx_window << std::endl;

  ret_val = window_params.tx_weight * tx_window + window_params.dx_weight * qop_window;
  if (ret_val > window_params.max_window_layer0) {
    ret_val = window_params.max_window_layer0;
  }
  return ret_val;
}

void linear_regression(const std::vector<float>& x, const std::vector<float>& y, float& m, float& q, float& chi_2)
{
  float x_avg = 0;
  float x_var = 0;
  float x_y_cov = 0;
  float y_avg = 0;
  m = 0;
  q = 0;
  chi_2 = 0;
  for (int k = 0; k < x.size(); k++) {
    x_avg += x[k];
    y_avg += y[k];
  }
  x_avg /= x.size();
  y_avg /= x.size();

  for (int k = 0; k < x.size(); k++) {
    x_var += (x[k] - x_avg) * (x[k] - x_avg);
    x_y_cov += (x[k] - x_avg) * (y[k] - y_avg);
  }

  m = x_y_cov / x_var;
  q = y_avg - m * x_avg;
  chi_2 = get_chi_2(x, y, [&m, &q](double x) { return m * x + q; });
}

float get_chi_2(const std::vector<float>& x, const std::vector<float>& y, std::function<float(float)> expected_function)
{
  float chi_2 = 0;
  for (int k = 0; k < x.size(); k++) {
    const float expected_y = expected_function(x[k]);
    chi_2 += (y[k] - expected_y) * (y[k] - expected_y);
  }

  return chi_2;
}

std::tuple<int, int> find_x_in_window(
  const SciFi::Hits& hits,
  const int zone_offset,
  const int num_hits,
  const float value,
  const float margin)
{
  return find_x_in_window(hits, zone_offset, num_hits, value, value, margin);
}

std::tuple<int, int> find_x_in_window(
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
    last_candidate = first_candidate + last_candidate + 1;
  }

  return {first_candidate, last_candidate};
}

std::tuple<int, float> get_best_hit(
  const SciFi::Hits& hits,
  int layer_0_idx,
  int layer_3_idx,
  float slope,
  const std::tuple<int, int>& layer_candidates,
  const std::array<MiniState, 4>& proj_states,
  const SciFiWindowsParams& window_params,
  int layer)
{
  float m, q, chi_2, min_chi2;
  int best_idx;
  std::vector<float> x_coordinates(3, 0), z_coordinates(3, 0);
  z_coordinates[0] = proj_states[0].z;
  z_coordinates[1] = proj_states[layer].z;
  z_coordinates[2] = proj_states[3].z;

  x_coordinates[0] = hits.x0[layer_0_idx];
  x_coordinates[2] = hits.x0[layer_3_idx];

  m = slope;
  q = x_coordinates[0] - z_coordinates[0] * m;

  best_idx = -1;
  min_chi2 = window_params.chi2_cut;
  for (auto hit_layer_idx = std::get<0>(layer_candidates); hit_layer_idx != std::get<1>(layer_candidates);
       hit_layer_idx++) {
    x_coordinates[1] = hits.x0[hit_layer_idx] + proj_states[layer].y * SciFi::LookingForward::Zone_dxdy[layer];
    chi_2 = get_chi_2(z_coordinates, x_coordinates, [m, q](float x) { return m * x + q; });

    if (chi_2 < min_chi2) {
      best_idx = hit_layer_idx;
      min_chi2 = chi_2;
    }
  }

  return {best_idx, min_chi2};
}

void filter_tracks_with_TMVA(
  std::vector<SciFi::TrackHits>& tracks,
  std::vector<SciFi::TrackHits>& selected_tracks,
  const MiniState& velo_state,
  const float VeloUT_qOverP,
  const SciFi::Tracking::Arrays* constArrays,
  const SciFi::Tracking::TMVA* tmva1,
  const SciFi::Tracking::TMVA* tmva2,
  const SciFi::Hits& scifi_hits,
  const int event_offset)
{
  float best_quality = SciFi::Tracking::maxQuality;
  int best_candidate = -1;

  for (int k=0; k<tracks.size(); ++k) {
    auto& candidate = tracks[k];
    if (candidate.hitsNum < SciFi::LookingForward::minHits) continue;

    // use only hits from x-planes to calculate the average x position on the reference plane
    std::vector<int> x_hits;
    for (int i = 0; i < candidate.hitsNum; ++i) {
      if (scifi_hits.dxdy(candidate.hits[i] + event_offset) == 0) {
        x_hits.push_back(candidate.hits[i] + event_offset);
      }
    }
    const float xAtRef_initial = xFromVelo(SciFi::Tracking::zReference, velo_state);
    const float xParams_seed[4] = {xAtRef_initial, velo_state.tx, 0.f, 0.f};
    float zMag_initial = zMagnet(velo_state, constArrays);
    float xAtRef_average =
      get_average_x_at_reference_plane(x_hits, scifi_hits, xParams_seed, constArrays, velo_state, zMag_initial);

    // debug_cout << "Found " << x_hits.size() << " x hits on track, average ref = " << xAtRef_average << std::endl;
    // initial track parameters
    float trackParams[SciFi::Tracking::nTrackParams];
    getTrackParameters(xAtRef_average, velo_state, constArrays, trackParams);
    // debug_cout << "BEFORE" << std::endl;
    // debug_cout << "0 = " << trackParams[0] << ", 1 = " << trackParams[1] << ", 2 = " << trackParams[2] << ", 3 = " <<
    // trackParams[3] << ", 4 = " << trackParams[4] << ", 5 = " << trackParams[5] << ", 6 = " << trackParams[6] << ", 7
    // = " << trackParams[7] << ", 8 = " << trackParams[8] << std::endl;

    // make a fit of ALL hits using their x coordinate
    if (!fitParabola(candidate, scifi_hits, event_offset, trackParams)) continue;

    // debug_cout << "AFTER" << std::endl;
    // debug_cout << "0 = " << trackParams[0] << ", 1 = " << trackParams[1] << ", 2 = " << trackParams[2] << ", 3 = " <<
    // trackParams[3] << ", 4 = " << trackParams[4] << ", 5 = " << trackParams[5] << ", 6 = " << trackParams[6] << ", 7
    // = " << trackParams[7] << ", 8 = " << trackParams[8] << std::endl;

    // Calculate q/p
    const float qOverP = calcqOverP(trackParams[1], constArrays, velo_state);
    const float xAtRef = trackParams[0];
    float dSlope = (velo_state.x + (SciFi::Tracking::zReference - velo_state.z) * velo_state.tx - xAtRef) /
                   (SciFi::Tracking::zReference - constArrays->zMagnetParams[0]);
    const float zMagSlope =
      constArrays->zMagnetParams[2] * pow(velo_state.tx, 2) + constArrays->zMagnetParams[3] * pow(velo_state.ty, 2);
    const float zMag = constArrays->zMagnetParams[0] + constArrays->zMagnetParams[1] * dSlope * dSlope + zMagSlope;
    const float xMag = velo_state.x + (zMag - velo_state.z) * velo_state.tx;
    const float slopeT = (xAtRef - xMag) / (SciFi::Tracking::zReference - zMag);
    dSlope = slopeT - velo_state.tx;
    const float dyCoef = dSlope * dSlope * velo_state.ty;

    float bx = slopeT;
    float ay = velo_state.y + (SciFi::Tracking::zReference - velo_state.z) * velo_state.ty;
    float by = velo_state.ty + dyCoef * SciFi::Tracking::byParams;

    const float ay1 = trackParams[4];
    const float by1 = trackParams[5];
    const float bx1 = trackParams[1];

    // Pipe into TMVA, get track quality
    float mlpInput[7] = {0};
    mlpInput[0] = candidate.hitsNum; // should be nbDifferent, but we only allow hits from different planes anyway
    mlpInput[1] = qOverP;
    mlpInput[2] = VeloUT_qOverP - qOverP;                // veloUT - scifi
    if (fabsf(VeloUT_qOverP) < 1e-9f) mlpInput[2] = 0.f; // no momentum estiamte
    mlpInput[3] = pow(velo_state.tx, 2) + pow(velo_state.ty, 2);
    mlpInput[4] = by - by1;
    mlpInput[5] = bx - bx1;
    mlpInput[6] = ay - ay1;

    float quality = GetMvaValue(mlpInput, tmva1);
    quality = 1.f - quality;

    // if (quality < SciFi::Tracking::maxQuality) {
    //   SciFi::TrackHits final_track = candidate;
    //   candidate.quality = float(trackParams[7]) / float(trackParams[8]); // chi2/nDoF
    //   candidate.qop = qOverP;
    //   selected_tracks.push_back(final_track);
    // }
    
    if (quality < best_quality) {
      best_quality = quality;
      best_candidate = k;
    }
  }

  if (best_candidate != -1) {
    selected_tracks.push_back(tracks[best_candidate]);
  }
}
