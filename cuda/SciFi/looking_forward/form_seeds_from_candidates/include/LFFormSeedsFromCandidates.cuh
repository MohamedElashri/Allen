#pragma once

#include "LookingForwardConstants.cuh"
#include "LookingForwardTools.cuh"
#include "LFFormSeedsFromCandidatesImpl.cuh"
#include "VeloConsolidated.cuh"
#include "UTConsolidated.cuh"
#include "SciFiEventModel.cuh"
#include "Handler.cuh"
#include "ArgumentsVelo.cuh"
#include "ArgumentsUT.cuh"
#include "ArgumentsSciFi.cuh"

__global__ void lf_form_seeds_from_candidates(
  uint32_t* dev_scifi_hits,
  const uint32_t* dev_scifi_hit_count,
  const int* dev_atomics_velo,
  const uint* dev_velo_track_hit_number,
  const char* dev_velo_states,
  const int* dev_atomics_ut,
  const char* dev_ut_track_hits,
  const uint* dev_ut_track_hit_number,
  const float* dev_ut_x,
  const float* dev_ut_tx,
  const float* dev_ut_z,
  const float* dev_ut_qop,
  const uint* dev_ut_track_velo_indices,
  SciFi::TrackCandidate* dev_scifi_track_candidates,
  int* dev_atomics_scifi,
  const char* dev_scifi_geometry,
  const LookingForward::Constants* dev_looking_forward_constants,
  const float* dev_inv_clus_res,
  const uint* dev_first_layer_candidates,
  const unsigned short* dev_second_layer_candidates,
  const uint station);

ALGORITHM(
  lf_form_seeds_from_candidates,
  lf_form_seeds_from_candidates_t,
  ARGUMENTS(
    dev_scifi_hits,
    dev_scifi_hit_count,
    dev_atomics_velo,
    dev_velo_track_hit_number,
    dev_velo_states,
    dev_atomics_ut,
    dev_ut_track_hits,
    dev_ut_track_hit_number,
    dev_ut_x,
    dev_ut_z,
    dev_ut_tx,
    dev_ut_qop,
    dev_ut_track_velo_indices,
    dev_scifi_track_candidates,
    dev_atomics_scifi,
    dev_scifi_lf_first_layer_candidates,
    dev_scifi_lf_second_layer_candidates))
