#pragma once

#include "LookingForwardUtils.h"
#include "FindXHits.cuh"

std::array<std::vector<int>, 6> collect_x_candidates(
  const SciFi::Hits& scifi_hits,
  const std::array<int, 2 * 6>& windows_x,
  const std::array<int, 2 * 6>& windows_uv,
  const std::array<float, 4 * 6>& parameters_uv);

std::vector<std::tuple<int, int>> find_compatible_window(
  const SciFi::Hits& scifi_hits,
  const int layer_from,
  const int layer_to,
  const std::vector<int>& hits_in_layer_from,
  const std::vector<int>& hits_in_layer_to,
  const float dx_stddev,
  const MiniState& UT_state,
  const float x_at_ref,
  const float z_mag);

float chi2_triplet(
  const SciFi::Hits& scifi_hits,
  const float qop,
  const int h0,
  const int h1,
  const int h2,
  const int l0,
  const int l1,
  const int l2);

std::tuple<int, int> find_x_in_window(
  const std::vector<int>& candidates,
  const SciFi::Hits& hits,
  const int num_hits,
  const float value,
  const float margin);

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
  const int layer2);
