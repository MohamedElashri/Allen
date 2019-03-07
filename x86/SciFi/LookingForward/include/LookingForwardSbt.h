#pragma once

#include "LookingForwardUtils.h"
#include "FindXHits.cuh"

// Quick class for tracklets
struct Tracklet {
  float quality = 0.f;
  int hits[6];
  int numHits = 0;
  Tracklet() : numHits(0), quality(0.f) {}
  void add_hit(const int hit) {
    hits[numHits++] = hit;
  }
  void add_hit_with_quality(const int hit, const float chi2) {
    hits[numHits++] = hit;
    quality += chi2;
  }
  float get_quality() {
    if (numHits < 3) {
      return 10000.f;
    } else {
      return quality / ((float) numHits - 2);
    }
  }
};

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
  const float compatible_window_factor,
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

std::vector<std::tuple<int, int, int, float>> find_triplets(
  const SciFi::Hits& scifi_hits,
  const float qop,
  const std::vector<bool>& flag,
  const int event_offset,
  const std::array<int, 6>& layers,
  const std::array<std::vector<int>, 6>& hits_in_layers,
  const int relative_layer0,
  const int relative_layer1,
  const int relative_layer2,
  const int max_candidates_triplet,
  const float max_triplet_chi2,
  const bool use_flagging);

std::vector<std::tuple<int, int, int, float>> find_triplets(
  const SciFi::Hits& scifi_hits,
  const float qop,
  const std::vector<std::tuple<int, int>>& compatible_hits_x0,
  const std::vector<std::tuple<int, int>>& compatible_hits_x2,
  const std::vector<bool>& flag,
  const int event_offset,
  const std::array<int, 6>& layers,
  const std::array<std::vector<int>, 6>& hits_in_layers,
  const int relative_layer0,
  const int relative_layer1,
  const int relative_layer2,
  const int max_candidates_triplet,
  const float max_triplet_chi2,
  const bool use_flagging);

std::vector<std::tuple<int, int>> find_extend_windows(
  const SciFi::Hits& scifi_hits,
  const MiniState& UT_state,
  const float qop,
  const std::array<int, 6>& layers,
  const std::array<std::vector<int>, 6>& hits_in_layers,
  const int relative_layer0,
  const int relative_layer1,
  const int relative_layer2,
  const int dx_extrapolation_max,
  const std::vector<std::tuple<int, int, int, float>>& triplets);

void extend_triplets (
  const SciFi::Hits& scifi_hits,
  const MiniState& UT_state,
  const float qop,
  const std::array<int, 6>& layers,
  const std::array<std::vector<int>, 6>& hits_in_layers,
  const int relative_layer0,
  const int relative_layer1,
  const int relative_layer2,
  const std::vector<std::tuple<int, int, int, float>>& triplets,
  const std::vector<std::tuple<int, int>>& extend_candidates_windows,
  const int event_offset,
  const float max_chi2,
  std::vector<Tracklet>& tracklets,
  std::vector<bool>& flag);

void extend_tracklets(
  const SciFi::Hits& scifi_hits,
  const MiniState& UT_state,
  const float qop,
  const std::array<int, 6>& layers,
  const std::array<std::vector<int>, 6>& hits_in_layers,
  const int relative_layer2,
  const int event_offset,
  const float max_chi2,
  std::vector<Tracklet>& tracklets,
  std::vector<bool>& flag);
