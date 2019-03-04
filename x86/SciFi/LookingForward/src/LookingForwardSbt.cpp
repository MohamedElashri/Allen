#include "LookingForwardSbt.h"

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
