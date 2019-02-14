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

#include <functional>

struct SciFiWindowsParams {
  float dx_slope = 5e-4;
  float max_window_layer0 = 200;
  float max_window_layer1 = 10; // 20;
  float max_window_layer2 = 10; // 20;
  float max_window_layer3 = 20; // 40;
  float chi2_cut = 100;         // 40;
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
  const SciFiWindowsParams& window_params);

float dx_calc(float qop, const SciFiWindowsParams& window_params);

void find_x_in_window(
  const SciFi::Hits& hits,
  const int num_hits,
  const int zone_offset,
  const float x_min,
  const float x_max,
  int& offset_begin,
  int& offset_end);

float linear_propagation(float x_0, float tx, float dz);

float get_chi_2(
  const std::vector<float>& x,
  const std::vector<float>& y,
  std::function<float(float)> expected_function);

void linear_regression(const std::vector<float>& x, const std::vector<float>& y, float& m, float& q, float& chi_2);
