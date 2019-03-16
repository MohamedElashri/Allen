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
#include "SciFiParametrization.h"
#include "TrackUtils.cuh"
#include "LookingForwardFitting.h"
#include "TMVA_Forward.cuh"
#include "TMVA_Forward_1.cuh"
#include "TMVA_Forward_2.cuh"
#include "LookingForwardConstants.cuh"

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
  int maximum_iteration_l3_window = 4;
  float extrapolation_stddev [8] {3.63f, 3.73f, 3.51f, 2.99f, 1.50f, 2.34f, 2.30f, 1.f};
  float chi2_extrap_mean   [8] {13.21f, 13.93f, 12.34f,  8.96f,  2.29f,  5.52f, 5.35f, 1.03f};
  float chi2_extrap_stddev [8] {116.5f, 104.5f, 98.35f, 80.66f, 24.11f, 35.91f, 36.7f, 9.72f};
  float chi2_track_mean = 6.78f;
  float chi2_track_stddev = 45.28f;
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

void propagate_candidates(
  const int layer,
  const SciFi::Hits& hits,
  const SciFi::HitCount& hit_count,
  const MiniState& velo_UT_state,
  const std::vector<SciFi::TrackHits>& candidates,
  std::vector<bool>& candidates_extrapolated,
  std::vector<SciFi::TrackHits>& tracks,
  const SciFiWindowsParams& window_params);

void propagate_tracks(
  const int layer,
  const SciFi::Hits& hits,
  const SciFi::HitCount& hit_count,
  const MiniState& velo_UT_state,
  std::vector<SciFi::TrackHits>& tracks,
  const SciFiWindowsParams& window_params);

bool single_candidate_propagation(
  const int layer,
  const SciFi::Hits& hits,
  const SciFi::HitCount& hit_count,
  const MiniState& velo_UT_state,
  const SciFi::TrackHits& candidate,
  std::vector<SciFi::TrackHits>& tracks,
  const float extrapolation_stddev,
  const float chi2_extrap_mean,
  const float chi2_extrap_stddev);

void single_track_propagation(
  const int layer,
  const SciFi::Hits& hits,
  const SciFi::HitCount& hit_count,
  const MiniState& velo_UT_state,
  SciFi::TrackHits& track,
  const float extrapolation_stddev,
  const float chi2_extrap_mean,
  const float chi2_extrap_stddev);

float dx_calc(const MiniState& state, float qop, const SciFiWindowsParams& window_params);

std::tuple<int, int> find_x_in_window(
  const SciFi::Hits& hits,
  const int zone_offset,
  const int num_hits,
  const float value,
  const float margin);

std::tuple<int, int> find_x_in_window(
  const SciFi::Hits& hits,
  const int zone_offset,
  const int num_hits,
  const float value0,
  const float value1,
  const float margin);

float linear_propagation(float x_0, float tx, float dz);

float scifi_propagation(const float x_0, const float tx, const float qop, const float dz);

float qop_update(
  const MiniState& UT_state,
  const float h0_x,
  const float h1_x,
  const float h0_z,
  const float h1_z,
  int layer);

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

float TMVA_quality (SciFi::TrackHits& track,
  const MiniState& velo_state,
  const float VeloUT_qOverP,
  const SciFi::Tracking::Arrays* constArrays,
  const SciFi::Tracking::TMVA* tmva1,
  const SciFi::Tracking::TMVA* tmva2,
  const SciFi::Hits& scifi_hits,
  const int event_offset);

void filter_tracks_with_TMVA( 
  std::vector<SciFi::TrackHits>& tracks,
  std::vector<SciFi::TrackHits>& selected_tracks,
  const MiniState& velo_state,
  const float VeloUT_qOverP,
  const SciFi::Tracking::Arrays* constArrays,
  const SciFi::Tracking::TMVA* tmva1,
  const SciFi::Tracking::TMVA* tmva2,
  const SciFi::Hits& scifi_hits,
  const int event_offset);

