#pragma once

#include "VeloEventModel.cuh"
#include "VeloConsolidated.cuh"
#include "States.cuh"
#include "Common.h"
#include "Handler.cuh"
#include "ArgumentsCommon.cuh"
#include "ArgumentsVelo.cuh"
#include <cstdint>

__global__ void consolidate_velo_tracks(
  uint* dev_atomics_velo,
  const Velo::TrackHits* dev_tracks,
  uint* dev_velo_track_hit_number,
  uint* dev_velo_cluster_container,
  uint* dev_module_cluster_start,
  char* dev_velo_track_hits,
  char* dev_velo_states);

ALGORITHM(
  consolidate_velo_tracks,
  consolidate_velo_tracks_t,
  ARGUMENTS(
    dev_atomics_velo,
    dev_tracks,
    dev_velo_track_hit_number,
    dev_velo_cluster_container,
    dev_estimated_input_size,
    dev_velo_track_hits,
    dev_velo_states,
    dev_accepted_velo_tracks))
