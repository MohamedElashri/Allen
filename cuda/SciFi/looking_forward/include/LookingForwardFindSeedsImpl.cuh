#pragma once

#include "LookingForwardConstants.cuh"
#include "LookingForwardTools.cuh"

__device__ void looking_forward_find_seeds_impl(
  const MiniState& velo_ut_state,
  const float ut_qop,
  const uint ut_track_index,
  const SciFi::Hits& hits,
  const SciFi::HitCount& hit_count,
  const int station,
  int* atomics,
  SciFi::TrackHits* scifi_tracks);

