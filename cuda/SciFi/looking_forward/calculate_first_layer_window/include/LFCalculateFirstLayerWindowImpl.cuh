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
  uint* first_candidates,
  uint* number_of_candidates,
  MiniState* ut_states,
  const int candidate_index);
