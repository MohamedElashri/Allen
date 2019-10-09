#pragma once

#include "LookingForwardConstants.cuh"
#include "LookingForwardTools.cuh"
#include "SciFiEventModel.cuh"
#include "Handler.cuh"
#include "ArgumentsSciFi.cuh"
#include "ArgumentsUT.cuh"
#include "ArgumentsVelo.cuh"
#include "UTConsolidated.cuh"
#include "TrackUtils.cuh"
#include "LFFit.cuh"

__global__ void lf_quality_filter_x(
  const uint* dev_atomics_ut,
  const uint* dev_ut_track_hit_number,
  const float* dev_ut_qop,
  const uint* dev_ut_track_velo_indices,
  const char* dev_velo_states,
  const uint* dev_atomics_velo,
  const uint* dev_velo_track_hit_number,
  const uint32_t* dev_scifi_hits,
  const uint32_t* dev_scifi_hit_count,
  const SciFi::TrackHits* dev_scifi_lf_tracks,
  const uint* dev_scifi_lf_atomics,
  SciFi::TrackHits* dev_scifi_lf_x_filtered_tracks,
  uint* dev_scifi_lf_x_filtered_atomics,
  float* dev_scifi_lf_xAtRef,
  const char* dev_scifi_geometry,
  const float* dev_inv_clus_res,
  const LookingForward::Constants* dev_looking_forward_constants,
  const SciFi::Tracking::Arrays* constArrays);

ALGORITHM(
  lf_quality_filter_x,
  lf_quality_filter_x_t,
  ARGUMENTS(
    dev_atomics_ut,
    dev_ut_track_hit_number,
    dev_ut_qop,
    dev_ut_track_velo_indices,
    dev_velo_states,
    dev_atomics_velo,
    dev_velo_track_hit_number,
    dev_scifi_hits,
    dev_scifi_hit_count,
    dev_scifi_lf_tracks,
    dev_scifi_lf_atomics,
    dev_scifi_lf_x_filtered_tracks,
    dev_scifi_lf_x_filtered_atomics,
    dev_scifi_lf_xAtRef))
