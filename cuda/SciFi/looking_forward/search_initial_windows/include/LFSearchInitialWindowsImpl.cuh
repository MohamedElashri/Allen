#pragma once

#include <cmath>
#include <array>
#include <vector>
#include <algorithm>
#include <fstream>
#include "SciFiDefinitions.cuh"
#include "UTDefinitions.cuh"
#include "SciFiEventModel.cuh"
#include "LookingForwardConstants.cuh"

__device__ void lf_search_initial_windows_impl(
  SciFi::ConstHits& scifi_hits,
  SciFi::ConstHitCount& scifi_hit_count,
  const MiniState& UT_state,
  const LookingForward::Constants* looking_forward_constants,
  const float qop,
  const bool side,
  int* initial_windows,
  const int number_of_tracks,
  const uint event_offset,
  bool* dev_process_track,
  const uint ut_track_index);
