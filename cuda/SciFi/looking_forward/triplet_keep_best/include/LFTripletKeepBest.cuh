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

__global__ void lf_triplet_keep_best(
  uint32_t* dev_scifi_hits,
  const uint32_t* dev_scifi_hit_count,
  const uint* dev_atomics_ut,
  const MiniState* dev_ut_states,
  const char* dev_scifi_geometry,
  const float* dev_inv_clus_res,
  const short* dev_scifi_lf_candidates,
  const LookingForward::Constants* dev_looking_forward_constants,
  SciFi::TrackHits* dev_scifi_tracks,
  uint* dev_atomics_scifi,
  const SciFi::CombinedValue* dev_scifi_lf_triplet_best);

ALGORITHM(
  lf_triplet_keep_best,
  lf_triplet_keep_best_t,
  ARGUMENTS(
    dev_scifi_hits,
    dev_scifi_hit_count,
    dev_atomics_ut,
    dev_ut_states,
    dev_scifi_lf_candidates,
    dev_scifi_lf_tracks,
    dev_scifi_lf_atomics,
    dev_scifi_lf_triplet_best))
