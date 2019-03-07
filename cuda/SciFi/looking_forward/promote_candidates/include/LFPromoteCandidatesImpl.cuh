#pragma once

#include "LookingForwardConstants.cuh"
#include "LookingForwardTools.cuh"

__device__ std::tuple<int16_t, float> lf_promote_candidates_impl(
  const float projection_y,
  const unsigned short first_extrapolated_candidate,
  const unsigned short size_extrapolated_candidates,
  const SciFi::Hits& hits,
  const SciFi::HitCount& hit_count,
  const LookingForward::Constants* dev_looking_forward_constants,
  const SciFi::TrackCandidate& track_candidate,
  const uint8_t layer);
