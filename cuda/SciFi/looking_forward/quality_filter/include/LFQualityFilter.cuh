#pragma once

#include "LookingForwardConstants.cuh"
#include "LookingForwardTools.cuh"
#include "LFTrackQuality.cuh"
#include "SciFiEventModel.cuh"
#include "Handler.cuh"
#include "ArgumentsVelo.cuh"
#include "ArgumentsUT.cuh"
#include "ArgumentsSciFi.cuh"
#include "TMVA_Forward.cuh"
#include "TMVA_Forward_1.cuh"
#include "TMVA_Forward_2.cuh"
#include "VeloConsolidated.cuh"
#include "UTConsolidated.cuh"
#include "LFFit.cuh"

__global__ void lf_quality_filter(
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
  float* dev_scifi_lf_track_params,
  const char* dev_scifi_geometry,
  const float* dev_inv_clus_res,
  const SciFi::Tracking::TMVA* dev_tmva1,
  const SciFi::Tracking::Arrays* constArrays,
  const float* dev_magnet_polarity,
  uint* dev_atomics_scifi,
  uint* dev_scifi_selected_track_indices,
  SciFi::TrackHits* dev_scifi_tracks);

ALGORITHM(
  lf_quality_filter,
  lf_quality_filter_t,
  ARGUMENTS(
    dev_scifi_hits,
    dev_scifi_hit_count,
    dev_atomics_velo,
    dev_velo_track_hit_number,
    dev_velo_states,
    dev_atomics_ut,
    dev_ut_track_hit_number,
    dev_ut_qop,
    dev_ut_track_velo_indices,
    dev_scifi_tracks,
    dev_atomics_scifi,
    dev_ut_states,
    dev_scifi_selected_track_indices,
    dev_scifi_lf_track_params,
    dev_scifi_lf_length_filtered_atomics,
    dev_scifi_lf_length_filtered_tracks))
