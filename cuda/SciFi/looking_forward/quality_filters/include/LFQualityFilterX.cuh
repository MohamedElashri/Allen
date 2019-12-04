#pragma once

#include "LookingForwardConstants.cuh"
#include "LookingForwardTools.cuh"
#include "SciFiEventModel.cuh"
#include "Handler.cuh"
#include "ArgumentsSciFi.cuh"
#include "ArgumentsUT.cuh"
#include "ArgumentsVelo.cuh"
#include "UTConsolidated.cuh"

__global__ void lf_quality_filter_x(
  const uint* dev_atomics_ut,
  const SciFi::TrackHits* dev_scifi_lf_tracks,
  const uint* dev_scifi_lf_atomics,
  SciFi::TrackHits* dev_scifi_lf_x_filtered_tracks,
  uint* dev_scifi_lf_x_filtered_atomics,
  const float* dev_scifi_lf_parametrization,
  float* dev_scifi_lf_parametrization_x_filter);

ALGORITHM(
  lf_quality_filter_x,
  lf_quality_filter_x_t,
  ARGUMENTS(
    dev_atomics_ut,
    dev_scifi_lf_tracks,
    dev_scifi_lf_atomics,
    dev_scifi_lf_x_filtered_tracks,
    dev_scifi_lf_x_filtered_atomics,
    dev_scifi_lf_parametrization,
    dev_scifi_lf_parametrization_x_filter))
