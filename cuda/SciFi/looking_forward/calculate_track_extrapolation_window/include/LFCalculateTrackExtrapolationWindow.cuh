#pragma once

#include "LookingForwardConstants.cuh"
#include "LookingForwardTools.cuh"
#include "LFCalculateTrackExtrapolationWindowImpl.cuh"
#include "VeloConsolidated.cuh"
#include "UTConsolidated.cuh"
#include "SciFiEventModel.cuh"
#include "Handler.cuh"
#include "ArgumentsVelo.cuh"
#include "ArgumentsUT.cuh"
#include "ArgumentsSciFi.cuh"

__global__ void lf_calculate_track_extrapolation_window(
  uint32_t* dev_scifi_hits,
  const uint32_t* dev_scifi_hit_count,
  const int* dev_atomics_ut,
  const SciFi::TrackHits* dev_scifi_tracks,
  const int* dev_atomics_scifi,
  const char* dev_scifi_geometry,
  const LookingForward::Constants* dev_looking_forward_constants,
  const float* dev_inv_clus_res,
  const MiniState* dev_ut_states,
  const uint8_t layer,
  unsigned short* dev_extrapolation_layer_candidates);

ALGORITHM(
  lf_calculate_track_extrapolation_window,
  lf_calculate_track_extrapolation_window_t,
  ARGUMENTS(
    dev_scifi_hits,
    dev_scifi_hit_count,
    dev_atomics_ut,
    dev_ut_states,
    dev_scifi_tracks,
    dev_atomics_scifi,
    dev_extrapolation_layer_candidates))
