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
#include "LFFitTools.cuh"

__global__ void lf_quality_filter(
  const uint32_t* dev_scifi_hits,
  const uint32_t* dev_scifi_hit_count,
  const uint* dev_atomics_ut,
  SciFi::TrackHits* dev_scifi_lf_tracks,
  const uint* dev_scifi_lf_atomics,
  const char* dev_scifi_geometry,
  const float* dev_inv_clus_res,
  uint* dev_atomics_scifi,
  SciFi::TrackHits* dev_scifi_tracks,
  const LookingForward::Constants* dev_looking_forward_constants,
  const float* dev_scifi_lf_parametrization_length_filter,
  float* dev_scifi_lf_y_parametrization_length_filter,
  float* dev_scifi_lf_parametrization_consolidate,
  const MiniState* dev_ut_states);

ALGORITHM(
  lf_quality_filter,
  lf_quality_filter_t,
  ARGUMENTS(
    dev_scifi_hits,
    dev_scifi_hit_count,
    dev_atomics_ut,
    dev_scifi_lf_length_filtered_tracks,
    dev_scifi_lf_length_filtered_atomics,
    dev_atomics_scifi,
    dev_scifi_tracks,
    dev_scifi_lf_parametrization_length_filter,
    dev_scifi_lf_y_parametrization_length_filter,
    dev_scifi_lf_parametrization_consolidate,
    dev_ut_states))
