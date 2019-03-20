#pragma once

#include <cmath>
#include <array>
#include <vector>
#include <algorithm>
#include <fstream>
#include "SciFiDefinitions.cuh"
#include "PrForwardConstants.cuh"
#include "UTDefinitions.cuh"
#include "TrackUtils.cuh"
#include "HitUtils.cuh"
#include "LinearFitting.cuh"
#include "ReferencePlaneProjection.cuh"
#include "PrVeloUT.cuh"
#include "SciFiEventModel.cuh"
#include "LookingForwardUtils.h"

__device__ inline float evalCubicParameterization(
  const float value_at_ref,
  const float t,
  const float z);

__device__ MiniState get_state_at_z(const MiniState state, const float z);

__device__ MiniState propagate_state_from_velo_to_SciFi(
  const MiniState& UT_state, 
  float qop, 
  int layer,
  const LookingForward::Constants* looking_forward_constants);

__device__ float xTol_calc(const MiniState& state, const float qop);

__device__ void lf_search_initial_windows_p_impl(
  const SciFi::Hits& scifi_hits,
  const SciFi::HitCount& scifi_hit_count,
  const MiniState& velo_state,
  const MiniState& UT_state,
  const SciFi::Tracking::Arrays* constArrays,
  const LookingForward::Constants* looking_forward_constants,
  const float qop,
  const int side,
  int* initial_windows,
  const int number_of_tracks);

__device__ void lf_search_initial_windows_impl(
  const SciFi::Hits& scifi_hits,
  const SciFi::HitCount& scifi_hit_count,
  const float xAtRef,
  const float yAtRef,
  const MiniState& velo_state,
  const SciFi::Tracking::Arrays* constArrays,
  const float qOverP,
  const int side,
  int* initial_windows,
  const int number_of_tracks);
