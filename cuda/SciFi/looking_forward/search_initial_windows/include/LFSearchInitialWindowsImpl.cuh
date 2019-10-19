#pragma once

#include <cmath>
#include <array>
#include <vector>
#include <algorithm>
#include <fstream>
#include "SciFiDefinitions.cuh"
#include "UTDefinitions.cuh"
#include "SciFiEventModel.cuh"
#include "TrackUtils.cuh"
#include "LookingForwardConstants.cuh"

__device__ inline float evalCubicParameterization(const float value_at_ref, const float t, const float z);

__device__ void lf_search_initial_windows_impl(
  const SciFi::Hits& scifi_hits,
  const SciFi::HitCount& scifi_hit_count,
  const MiniState& UT_state,
  const LookingForward::Constants* looking_forward_constants,
  const float qop,
  const int side,
  int* initial_windows,
  const int number_of_tracks,
  const uint event_offset);
