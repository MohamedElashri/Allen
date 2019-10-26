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

__global__ void lf_triplet_seeding(
  uint32_t* dev_scifi_hits,
  const uint32_t* dev_scifi_hit_count,
  const uint* dev_atomics_velo,
  const char* dev_velo_states,
  const uint* dev_atomics_ut,
  const uint* dev_ut_track_hit_number,
  const uint* dev_ut_track_velo_indices,
  const float* dev_ut_qop,
  const char* dev_scifi_geometry,
  const float* dev_inv_clus_res,
  const int* dev_initial_windows,
  const LookingForward::Constants* dev_looking_forward_constants,
  const MiniState* dev_ut_states,
  float* dev_scifi_lf_triplet_best,
  const bool* dev_scifi_lf_process_track,
  int16_t* dev_scifi_lf_found_triplets,
  int16_t* dev_scifi_lf_number_of_found_triplets);

ALGORITHM(
  lf_triplet_seeding,
  lf_triplet_seeding_t,
  ARGUMENTS(
    dev_scifi_hits,
    dev_scifi_hit_count,
    dev_atomics_ut,
    dev_ut_qop,
    dev_scifi_lf_initial_windows,
    dev_scifi_lf_triplet_best,
    dev_ut_states,
    dev_ut_track_hit_number,
    dev_ut_track_velo_indices,
    dev_atomics_velo,
    dev_velo_states,
    dev_scifi_lf_process_track,
    dev_scifi_lf_found_triplets,
    dev_scifi_lf_number_of_found_triplets))
