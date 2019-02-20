#pragma once

#include "LookingForwardConstants.cuh"
#include "LookingForwardTools.cuh"

__device__ void lf_form_seeds_from_candidates_impl(
  const MiniState& velo_ut_state,
  const float ut_qop,
  const unsigned short rel_ut_track_index,
  const SciFi::Hits& hits,
  const SciFi::HitCount& hit_count,
  const int station,
  const LookingForward::Constants* dev_looking_forward_constants,
  int* track_insert_atomic,
  SciFi::TrackCandidate* scifi_track_candidates,
  const unsigned short* second_candidate_ut_track_p,
  const uint total_number_of_candidates);
