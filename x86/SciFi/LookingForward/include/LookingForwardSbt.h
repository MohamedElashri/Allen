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

std::array<std::vector<int>, 6> collect_x_candidates_p(
  const SciFi::Hits& scifi_hits,
  const std::array<int, 2 * 6>& windows_x,
  const std::array<int, 2 * 6>& windows_uv,
  const float qOverP);

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
  const float tx, 
  const float qOverP, 
  const float z_mag);

std::vector<std::tuple<int, int>> find_compatible_window_p(
  const SciFi::Hits& scifi_hits,
  const int layer_from,
  const int layer_to,
  const std::vector<int>& hits_in_layer_from,
  const std::vector<int>& hits_in_layer_to,
  const float dx_stddev,
  const float compatible_window_factor, 
  const bool forward,
  const float qOverP);

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

std::tuple<int, int> find_x_in_window(
  const std::vector<int>& candidates,
  const SciFi::Hits& hits,
  const int num_hits,
  const float value0,
  const float value1,
  const float margin);

void find_triplets(
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
  const bool use_flagging,
  const uint16_t ut_track_index,
  const MiniState& UT_state,
  std::vector<SciFi::TrackHits>& scifi_tracks);

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

void extend_tracklets(
  const SciFi::Hits& scifi_hits,
  const MiniState& UT_state,
  const std::array<int, 6>& layers,
  const std::array<std::vector<int>, 6>& hits_in_layers,
  const int relative_layer2,
  const int event_offset,
  const float max_chi2,
  std::vector<SciFi::TrackHits>& tracklets,
  std::vector<bool>& flag);

void single_track_propagation(
  const SciFi::Hits& scifi_hits,
  const SciFi::HitCount& hit_count,
  const int layer,
  const float projection_y,
  SciFi::TrackHits& track,
  const float extrapolation_stddev,
  const float chi2_extrap_mean,
  const float chi2_extrap_stddev,
  const int event_offset,
  const std::vector<bool>& flag,
  const bool use_flagging = false);
