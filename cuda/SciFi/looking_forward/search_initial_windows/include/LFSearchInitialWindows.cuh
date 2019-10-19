#pragma once

#include "VeloConsolidated.cuh"
#include "UTConsolidated.cuh"
#include "SciFiEventModel.cuh"
#include "SciFiDefinitions.cuh"
#include "Handler.cuh"
#include "ArgumentsVelo.cuh"
#include "ArgumentsUT.cuh"
#include "ArgumentsSciFi.cuh"
#include "LookingForwardConstants.cuh"
#include "LookingForwardTools.cuh"
#include "TrackUtils.cuh"

__global__ void lf_search_initial_windows(
  uint32_t* dev_scifi_hits,
  const uint32_t* dev_scifi_hit_count,
  const uint* dev_atomics_velo,
  const uint* dev_velo_track_hit_number,
  const char* dev_velo_states,
  const uint* dev_atomics_ut,
  const uint* dev_ut_track_hit_number,
  const float* dev_ut_x,
  const float* dev_ut_tx,
  const float* dev_ut_z,
  const float* dev_ut_qop,
  const uint* dev_ut_track_velo_indices,
  const char* dev_scifi_geometry,
  const float* dev_inv_clus_res,
  const LookingForward::Constants* dev_looking_forward_constants,
  int* dev_initial_windows,
  MiniState* dev_ut_states);

ALGORITHM(
  lf_search_initial_windows,
  lf_search_initial_windows_t,
  ARGUMENTS(
    dev_scifi_hits,
    dev_scifi_hit_count,
    dev_atomics_velo,
    dev_velo_track_hit_number,
    dev_velo_states,
    dev_atomics_ut,
    dev_ut_track_hit_number,
    dev_ut_x,
    dev_ut_tx,
    dev_ut_z,
    dev_ut_qop,
    dev_ut_track_velo_indices,
    dev_ut_states,
    dev_scifi_lf_initial_windows))
