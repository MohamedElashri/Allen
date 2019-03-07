#pragma once

#include <cstdint>
#include "LookingForwardConstants.cuh"
#include "LookingForwardTools.cuh"
#include "SciFiEventModel.cuh"

__device__ void lf_calculate_track_extrapolation_window_impl(
  const float projection_y,
  const SciFi::Hits& hits,
  const SciFi::HitCount& hit_count,
  const LookingForward::Constants* dev_looking_forward_constants,
  const SciFi::TrackHits& track,
  const uint8_t layer,
  unsigned short* extrapolation_layer_candidates,
  const int extrapolation_candidates_offset);
