#pragma once

#include "CudaCommon.h"
#include "LookingForwardConstants.cuh"
#include "LookingForwardTools.cuh"
#include "SciFiEventModel.cuh"
#include "Handler.cuh"
#include "ArgumentsVelo.cuh"
#include "ArgumentsUT.cuh"
#include "ArgumentsSciFi.cuh"
#include "VeloConsolidated.cuh"
#include "UTConsolidated.cuh"
#include "LFFitTools.cuh"

__device__ void lf_fit_impl(
  SciFi::TrackHits& track,
  const int event_offset,
  const SciFi::Hits& scifi_hits,
  const LookingForward::Constants* dev_looking_forward_constants,
  const SciFi::Tracking::Arrays* constArrays,
  const MiniState velo_state,
  const float xAtRef_average,
  float* trackParams);

__global__ void lf_fit(
  const uint32_t* dev_scifi_hits,
  const uint32_t* dev_scifi_hit_count,
  const uint* dev_atomics_velo,
  const uint* dev_velo_track_hit_number,
  const char* dev_velo_states,
  const uint* dev_atomics_ut,
  const uint* dev_ut_track_hit_number,
  const float* dev_ut_qop,
  const uint* dev_ut_track_velo_indices,
  SciFi::TrackHits* dev_scifi_lf_tracks,
  const uint* dev_scifi_lf_atomics,
  const float* dev_scifi_lf_xAtRef_after_length_filter,
  const char* dev_scifi_geometry,
  const float* dev_inv_clus_res,
  const SciFi::Tracking::Arrays* constArrays,
  const LookingForward::Constants* dev_looking_forward_constants,
  float* dev_scifi_lf_track_params);

ALGORITHM(
  lf_fit,
  lf_fit_t,
  ARGUMENTS(
    dev_scifi_hits,
    dev_scifi_hit_count,
    dev_atomics_velo,
    dev_velo_track_hit_number,
    dev_velo_states,
    dev_atomics_ut,
    dev_ut_track_hits,
    dev_ut_track_hit_number,
    dev_ut_qop,
    dev_ut_track_velo_indices,
    dev_ut_tx,
    dev_scifi_lf_length_filtered_atomics,
    dev_scifi_lf_length_filtered_tracks,
    dev_scifi_lf_track_params,
    dev_scifi_lf_xAtRef_after_length_filter))
