#include "LookingForwardSbt.h"

std::tuple<int, float> single_candidate_propagation(
  const SciFi::Hits& hits,
  const SciFi::HitCount& hit_count,
  const MiniState& velo_UT_state,
  const float qop,
  const float extrapolation_stddev,
  const float chi2_extrap_mean,
  const float chi2_extrap_stddev,
  const int h0,
  const int h1,
  const int layer0,
  const int layer1,
  const int layer2)
{
  const auto projection_y = y_at_z(velo_UT_state, SciFi::LookingForward::Zone_zPos[layer2]);

  // do the propagation
  const auto x_at_layer0 = hits.x0[h0];
  const auto x_at_layer1 = hits.x0[h1];

  const auto reco_slope = (x_at_layer1 - x_at_layer0) /
    (SciFi::LookingForward::Zone_zPos[layer1] -
     SciFi::LookingForward::Zone_zPos[layer0]);

  const auto projection_x = scifi_propagation(
                              x_at_layer0,
                              reco_slope,
                              qop,
                              SciFi::LookingForward::Zone_zPos[layer2] - SciFi::LookingForward::Zone_zPos[layer0]) -
                            SciFi::LookingForward::Zone_dxdy[(layer2 % 4)] * projection_y;

  const auto layer_offset_nhits = get_offset_and_n_hits_for_layer(2 * layer2, hit_count, projection_y);
  const auto layer_candidates = find_x_in_window_margin(
    hits,
    std::get<0>(layer_offset_nhits),
    std::get<1>(layer_offset_nhits),
    projection_x,
    3 * extrapolation_stddev);

  // Pick the best, according to chi2
  int best_idx = -1;
  float best_chi2 = chi2_extrap_mean + 2.f * chi2_extrap_stddev;

  // We need a new lambda to compare in chi2
  const auto chi2_fn = [&x_at_layer0, &reco_slope, &qop, &layer0] (const float z) {
    return scifi_propagation(
      x_at_layer0,
      reco_slope,
      qop,
      z - SciFi::LookingForward::Zone_zPos[layer0]);
  };

  std::vector<float> x_coordinates {
    x_at_layer0,
    x_at_layer1,
    0.f};

  std::vector<float> z_coordinates {
    SciFi::LookingForward::Zone_zPos[layer0],
    SciFi::LookingForward::Zone_zPos[layer1],
    SciFi::LookingForward::Zone_zPos[layer2]};

  for (auto hit_index = std::get<0>(layer_candidates); hit_index != std::get<1>(layer_candidates); hit_index++) {
    x_coordinates[2] = hits.x0[hit_index];
    const auto chi2 = get_chi_2(z_coordinates, x_coordinates, chi2_fn);

    if (chi2 < best_chi2) {
      best_chi2 = chi2;
      best_idx = hit_index;
    }
  }

  return {best_idx, best_chi2};
}

std::array<std::vector<int>, 6> collect_x_candidates(
  const SciFi::Hits& scifi_hits,
  const std::array<int, 2 * 6>& windows_x,
  const std::array<int, 2 * 6>& windows_uv,
  const std::array<float, 4 * 6>& parameters_uv)
{
  std::array<std::vector<int>, 6> hits_in_layers;

  for (int i = 0; i < 6; ++i) {
    const auto window_start = windows_x[2 * i];
    const auto window_size = windows_x[2 * i + 1];
    if (window_size > 0) {
      const float zHit = scifi_hits.z0[window_start];
      for (int j = 0; j < window_size; ++j) {
        const auto hit_index = window_start + j;
        float xHit = scifi_hits.x0[hit_index];
        const float xPredUv = parameters_uv[4 * i] + xHit * parameters_uv[4 * i + 1];
        const float maxDx =
          parameters_uv[4 * i + 2] + fabsf(xHit - parameters_uv[4 * i + 3]) * SciFi::Tracking::tolYSlopeCollectX;
        const float xMinUV = xPredUv - maxDx;
        const float xMaxUV = xPredUv + maxDx;
        if (matchStereoHit(windows_uv[i * 2], windows_uv[i * 2 + 1], scifi_hits, xMinUV, xMaxUV)) {
          hits_in_layers[i].push_back(hit_index);
        }
      }
    }
  }

  return hits_in_layers;
}

float chi2_triplet(
  const SciFi::Hits& scifi_hits,
  const float qop,
  const int h0,
  const int h1,
  const int h2,
  const int l0,
  const int l1,
  const int l2)
{
  const auto x_at_layer_0 = scifi_hits.x0[h0];
  const auto x_at_layer_1 = scifi_hits.x0[h1];
  const auto x_at_layer_2 = scifi_hits.x0[h2];

  const auto z_at_layer_0 = SciFi::LookingForward::Zone_zPos[l0];
  const auto z_at_layer_1 = SciFi::LookingForward::Zone_zPos[l1];
  const auto z_at_layer_2 = SciFi::LookingForward::Zone_zPos[l2];

  const auto reco_slope = (x_at_layer_1 - x_at_layer_0) / (z_at_layer_1 - z_at_layer_0);

  const auto chi2_fn = [&x_at_layer_0, &z_at_layer_0, &reco_slope, &qop](const float z) {
    const auto dz = z - z_at_layer_0;
    return x_at_layer_0 + reco_slope * dz + SciFi::LookingForward::forward_param * qop * dz * dz;
  };

  std::vector<float> x_coordinates {x_at_layer_0, x_at_layer_1, x_at_layer_2};
  std::vector<float> z_coordinates {z_at_layer_0, z_at_layer_1, z_at_layer_2};

  return get_chi_2(z_coordinates, x_coordinates, chi2_fn);

  // dz0 = (z0 - z0);
  // dz1 = (z1 - z0);
  // dz2 = (z2 - z0);

  // extrap0 = SciFi::LookingForward::forward_param * qop * dz0 * dz0;
  // extrap1 = SciFi::LookingForward::forward_param * qop * dz1 * dz1;
  // extrap2 = SciFi::LookingForward::forward_param * qop * dz2 * dz2;

  // // 5 ops on TC gets 4 chi2s
  // tx = x1 * zdiff_inv - x0 * zdiff_inv;
  // ydiff0 = x0 - z0 + tx * dz0 + extrap0;
  // ydiff1 = x1 - z1 + tx * dz1 + extrap1;
  // ydiff2 = x2 - z2 + tx * dz2 + extrap2;
  // chi2 = ydiff0*ydiff0 + ydiff1*ydiff1 + ydiff2*ydiff2;
};

std::vector<std::tuple<int, int>> find_compatible_window(
  const SciFi::Hits& scifi_hits,
  const int layer_from,
  const int layer_to,
  const std::vector<int>& hits_in_layer_from,
  const std::vector<int>& hits_in_layer_to,
  const float dx_stddev,
  const MiniState& UT_state,
  const float x_at_ref,
  const float z_mag)
{
  std::vector<std::tuple<int, int>> compatible_hits_x0;

  const auto z1 = SciFi::LookingForward::Zone_zPos[layer_from];
  const auto z0 = SciFi::LookingForward::Zone_zPos[layer_to];
  const auto dSlopeDivPart = 1.f / (z1 - SciFi::LookingForward::zMagnetParams[0]);
  const auto dz = 1.e-3f * std::abs(z1 - z0);
  const float x_from_velo_hit = x_at_ref + UT_state.tx * z1;

  for (int h1_rel = 0; h1_rel < hits_in_layer_from.size(); ++h1_rel) {
    const auto h1_index = hits_in_layer_from[h1_rel];
    const auto x1 = scifi_hits.x0[h1_index];

    const auto dSlope = (x_from_velo_hit - x1) * dSlopeDivPart;
    const auto zMag_corrected = z_mag + SciFi::LookingForward::zMagnetParams[1] * dSlope * dSlope;
    const auto xMag = x_from_velo_hit + UT_state.tx * (zMag_corrected - z1);

    // calculate x position on reference plane (save in coodX)
    // dxCoef: account for additional bending of track due to fringe field in first station
    // expressed by quadratic and cubic term in z
    auto dxCoef =
      dz * dz * (SciFi::LookingForward::xParams[0] + dz * SciFi::LookingForward::xParams[1]) * dSlope;
    auto ratio = (z0 - zMag_corrected) / (z1 - zMag_corrected);
    auto extrapolated_value = xMag + ratio * (x1 + dxCoef - xMag);

    const auto x0_candidates = find_x_in_window(
      hits_in_layer_to,
      scifi_hits,
      hits_in_layer_to.size(),
      extrapolated_value,
      2 * dx_stddev);

    compatible_hits_x0.push_back(x0_candidates);
  }

  return compatible_hits_x0;
}

std::tuple<int, int> find_x_in_window(
  const std::vector<int>& candidates,
  const SciFi::Hits& hits,
  const int num_hits,
  const float value,
  const float margin)
{
  int first_candidate = binary_search_first_candidate((int*) candidates.data(), num_hits, hits.x0, value, margin);
  int last_candidate = -1;

  if (first_candidate != -1) {
    last_candidate = binary_search_second_candidate((int*) (candidates.data() + first_candidate), num_hits - first_candidate, hits.x0, value, margin);
    last_candidate = first_candidate + last_candidate;
  }

  return {first_candidate, last_candidate};
}
