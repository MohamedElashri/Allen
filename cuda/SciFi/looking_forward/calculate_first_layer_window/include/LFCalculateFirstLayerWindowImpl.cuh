#pragma once

#include "LookingForwardConstants.cuh"
#include "LookingForwardTools.cuh"

__device__ void lf_calculate_first_layer_window_impl(
  const MiniState& velo_ut_state,
  const float ut_qop,
  const SciFi::Hits& hits,
  const SciFi::HitCount& hit_count,
  const int seeding_first_layer,
  const LookingForward::Constants* dev_looking_forward_constants,
  short* first_candidates,
  short* last_candidates);
