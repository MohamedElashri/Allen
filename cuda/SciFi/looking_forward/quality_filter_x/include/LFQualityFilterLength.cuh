#pragma once

#include "LookingForwardConstants.cuh"
#include "LookingForwardTools.cuh"
#include "SciFiEventModel.cuh"
#include "Handler.cuh"
#include "ArgumentsSciFi.cuh"
#include "ArgumentsUT.cuh"

__global__ void lf_quality_filter_length(
  const uint* dev_atomics_ut,
  const SciFi::TrackHits* dev_scifi_lf_x_filtered_tracks,
  const uint* dev_scifi_lf_x_filtered_atomics,
  const float* dev_scifi_lf_xAtRef,
  float* dev_scifi_lf_xAtRef_after_length_filter,
  SciFi::TrackHits* dev_scifi_lf_length_filtered_tracks,
  uint* dev_scifi_lf_length_filtered_atomics);

ALGORITHM(
  lf_quality_filter_length,
  lf_quality_filter_length_t,
  ARGUMENTS(
    dev_atomics_ut,
    dev_scifi_lf_x_filtered_tracks,
    dev_scifi_lf_x_filtered_atomics,
    dev_scifi_lf_length_filtered_tracks,
    dev_scifi_lf_length_filtered_atomics,
    dev_scifi_lf_xAtRef,
    dev_scifi_lf_xAtRef_after_length_filter))
