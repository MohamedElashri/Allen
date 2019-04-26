#pragma once

#include "PrForwardConstants.cuh"
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

__global__ void lf_collect_candidates(
  uint32_t* dev_scifi_hits,
  const uint32_t* dev_scifi_hit_count,
  const int* dev_atomics_ut,
  const uint* dev_ut_track_hit_number,
  const float* dev_ut_qop,
  const uint* dev_ut_track_velo_indices,
  const char* dev_scifi_geometry,
  const float* dev_inv_clus_res,
  const int* dev_initial_windows,
  uint* dev_scifi_lf_number_of_candidates,
  short* dev_scifi_lf_candidates);

ALGORITHM(
  lf_collect_candidates,
  lf_collect_candidates_t,
  ARGUMENTS(
    dev_scifi_hits,
    dev_scifi_hit_count,
    dev_atomics_ut,
    dev_ut_track_hit_number,
    dev_ut_qop,
    dev_ut_track_velo_indices,
    dev_scifi_lf_initial_windows,
    dev_scifi_lf_number_of_candidates,
    dev_scifi_lf_candidates))
