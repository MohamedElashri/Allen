#pragma once

#include "LookingForwardConstants.cuh"
#include "LookingForwardTools.cuh"

__device__ void lf_form_seeds_from_candidates_impl(
  const MiniState& velo_ut_state,
  const float ut_qop,
  const unsigned short rel_ut_track_index,
  const SciFi::Hits& hits,
  const SciFi::HitCount& hit_count,
  const float* looking_forward_constants,
  int* track_insert_atomic,
  SciFi::TrackCandidate* scifi_track_candidates,
  const unsigned short first_candidate_index,
  const unsigned short second_candidate_offset,
  const unsigned short second_candidate_size,
  const unsigned short second_candidate_l1_start,
  const unsigned short second_candidate_l1_size,
  const unsigned short second_candidate_l2_start,
  const unsigned short second_candidate_l2_size);
