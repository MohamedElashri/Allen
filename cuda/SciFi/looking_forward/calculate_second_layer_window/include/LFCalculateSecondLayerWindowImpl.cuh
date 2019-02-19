#pragma once

#include "LookingForwardConstants.cuh"
#include "LookingForwardTools.cuh"

__device__ void lf_calculate_second_layer_window_impl(
  const MiniState& velo_ut_state,
  const float ut_qop,
  const SciFi::Hits& hits,
  const SciFi::HitCount& hit_count,
  const int seeding_first_layer,
  const int seeding_second_layer,
  const LookingForward::Constants* dev_looking_forward_constants,
  const uint relative_ut_track_index,
  const uint local_hit_offset_first_candidate,
  const uint size_first_candidate,
  unsigned short* second_candidate_ut_track,
  unsigned short* second_candidate_first_candidate,
  unsigned short* second_candidate_start,
  unsigned short* second_candidate_size,
  unsigned short* second_candidate_l1_start,
  unsigned short* second_candidate_l1_size,
  unsigned short* second_candidate_l2_start,
  unsigned short* second_candidate_l2_size);
