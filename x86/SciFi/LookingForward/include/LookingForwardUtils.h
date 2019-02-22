#pragma once

#include <cmath>
#include <array>
#include <vector>
#include <algorithm>
#include <fstream>

#include <cassert>

#include "SciFiDefinitions.cuh"
#include "SciFiEventModel.cuh"
#include "LookingForwardConstants.h"
#include "MomentumForwardUtils.h"
#include "BinarySearch.cuh"

#include <functional>

struct SciFiWindowsParams {
  float dx_slope = 4000000;
  float dx_min = 200;
  float dx_weight = 0.5;
  float tx_slope = 4000000;
  float tx_min = 200;
  float tx_weight = 0.5;
  float max_window_layer0 = 600;
  float max_window_layer1 = 10; // 20;
  float max_window_layer2 = 10; // 20;
  float max_window_layer3 = 20; // 40;
  float chi2_cut = 100;         // 40;
};

class Window_stat {
public:
  Window_stat() {}

  Window_stat(int num_hits, float x_center, float dx)
  {
    this->num_hits = num_hits;
    this->x_center = x_center;
    this->x_min = x_center - dx;
    this->x_max = x_center + dx;
  }

  Window_stat(int num_hits, float x_center, float x_min, float x_max)
  {
    this->num_hits = num_hits;
    this->x_center = x_center;
    this->x_min = x_min;
    this->x_max = x_max;
  }

  int num_hits;
  float x_center;
  float x_min, x_max;
};

float x_at_z(const MiniState& state, const float z);

MiniState propagate_state_from_velo(const MiniState& UT_state, float qop, int layer);

bool select_hits(
  const MiniState& velo_UT_state,
  float UT_qop,
  unsigned int UT_track_index,
  const SciFi::Hits& hits,
  const SciFi::HitCount& hit_count,
  const int station,
  std::vector<SciFi::TrackHits>& track_candidate,
  std::array<std::vector<Window_stat>, 4>& window_stats,
  const SciFiWindowsParams& window_params);

std::tuple<int, int>  get_u_or_v_layer_candidates(  
  const SciFi::Hits& hits,
  const SciFi::HitCount& hit_count,
  const int hit_layer_0_idx,
  const float slope_layer_3_layer_0_minx,
  const float slope_layer_3_layer_0_maxx,
  const MiniState& proj_state,
  const float dxdy,
  const int zone,
  std::vector<Window_stat>& window_stats,
  const float max_window);

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
  const SciFiWindowsParams& window_params);

float propagate_x_from_previous_station(  
  const SciFi::Hits& hits, 
  const SciFi::TrackHits& candidate,
  const int layer_0);

bool propagate_candidates( 
  const int station,
  const SciFi::Hits& hits,
  const SciFi::HitCount& hit_count,
  const MiniState& velo_UT_state,
  std::vector<SciFi::TrackHits>& track_candidates,
  std::array<std::vector<Window_stat>, 4>& window_stats,
  const SciFiWindowsParams& window_params);

float dx_calc(const MiniState& state, float qop, const SciFiWindowsParams& window_params);

std::tuple<int, int> find_x_in_window(
  const SciFi::Hits& hits,
  const int num_hits,
  const int zone_offset,
  const float x_min,
  const float x_max);

float linear_propagation(float x_0, float tx, float dz);

float scifi_propagation(const float x_0, const float tx, const float qop, const float dz);

float qop_upgrade(const MiniState& UT_state, float hit_layer_0, float hit_layer_3, int layer);

float get_chi_2(
  const std::vector<float>& x,
  const std::vector<float>& y,
  std::function<float(float)> expected_function);

void linear_regression(const std::vector<float>& x, const std::vector<float>& y, float& m, float& q, float& chi_2);

std::tuple<int, float> get_best_hit(
  const SciFi::Hits& hits,
  int layer_0_idx,
  int layer_3_idx,
  float slope,
  const std::tuple<int, int>& layer_candidates,
  const std::array<MiniState, 4>& proj_states,
  const SciFiWindowsParams& window_params,
  int layer);
