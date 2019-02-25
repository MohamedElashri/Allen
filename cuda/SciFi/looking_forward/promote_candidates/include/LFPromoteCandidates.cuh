#pragma once

#include "LookingForwardConstants.cuh"
#include "LookingForwardTools.cuh"
#include "LFPromoteCandidatesImpl.cuh"
#include "SciFiEventModel.cuh"
#include "Handler.cuh"
#include "ArgumentsUT.cuh"
#include "ArgumentsSciFi.cuh"

__global__ void lf_promote_candidates(
  uint32_t* dev_scifi_hits,
  const uint32_t* dev_scifi_hit_count,
  const int* dev_atomics_ut,
  const SciFi::TrackCandidate* dev_scifi_track_candidates,
  SciFi::TrackHits* dev_scifi_tracks,
  bool* dev_scifi_track_promoted_candidates,
  int* dev_atomics_scifi,
  const char* dev_scifi_geometry,
  const LookingForward::Constants* dev_looking_forward_constants,
  const float* dev_inv_clus_res,
  const MiniState* dev_ut_states,
  const uint8_t layer);

ALGORITHM(
  lf_promote_candidates,
  lf_promote_candidates_t,
  ARGUMENTS(
    dev_scifi_hits,
    dev_scifi_hit_count,
    dev_atomics_ut,
    dev_ut_states,
    dev_scifi_track_candidates,
    dev_scifi_tracks,
    dev_scifi_track_promoted_candidates,
    dev_atomics_scifi))
