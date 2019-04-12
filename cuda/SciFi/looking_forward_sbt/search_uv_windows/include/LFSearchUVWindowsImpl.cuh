#pragma once

#include "LookingForwardConstants.cuh"
#include "LookingForwardTools.cuh"
#include "UTDefinitions.cuh"

__device__ void lf_search_uv_windows_impl(
  const float* scifi_hits_x0,
  const SciFi::HitCount& scifi_hit_count,
  const SciFi::TrackHits& track,
  const float x0,
  const float x1,
  const float z0,
  const float z1,
  const uint event_number,
  const uint number_of_events,
  const uint event_offset,
  const LookingForward::Constants* dev_looking_forward_constants,
  const MiniState& ut_state,
  const int total_number_of_ut_tracks,
  const int current_ut_track_index,
  const int ut_event_number_of_tracks,
  short* dev_scifi_lf_uv_windows);
