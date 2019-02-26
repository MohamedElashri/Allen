#include "LookingForwardSbt.h"

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
    return scifi_propagation(x_at_layer_0, reco_slope, qop, z - z_at_layer_0);
  };

  std::vector<float> x_coordinates {x_at_layer_0, x_at_layer_1, x_at_layer_2};
  std::vector<float> z_coordinates {z_at_layer_0, z_at_layer_1, z_at_layer_2};

  return get_chi_2(z_coordinates, x_coordinates, chi2_fn);
};