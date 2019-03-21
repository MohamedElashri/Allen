#pragma once

#include "Common.h"
#include "LookingForwardConstants.cuh"
#include "SciFiEventModel.cuh"
#include "TrackUtils.cuh"

namespace LookingForward {

__device__ int fitParabola_proto(
  const SciFi::Hits& scifi_hits,
  const int* coordToFit,
  const int n_coordToFit,
  float trackParameters[SciFi::Tracking::nTrackParams],
  const bool xFit);

__device__ float get_average_x_at_reference_plane(
  const int* hits,
  const int n_hits,
  const SciFi::Hits& scifi_hits,
  const float xParams_seed[4],
  const SciFi::Tracking::Arrays* constArrays,
  const MiniState& velo_state,
  const float zMagSlope);

__device__ int getChi2( 
  const SciFi::Hits& scifi_hits,
  int* coordToFit,
  const int n_coordToFit,
  float trackParameters[SciFi::Tracking::nTrackParams],
  const bool xFit);

__device__ void removeOutlier_proto(
  const SciFi::Hits& scifi_hits,
  int* coordToFit,
  int& n_coordToFit,
  const int worst);

__device__ bool fitYProjection_proto(
  const MiniState& velo_state,
  const SciFi::Tracking::Arrays* constArrays,
  const int* uv_hits,
  const int n_uv_hits,
  const SciFi::Hits& scifi_hits,
  float trackParams[SciFi::Tracking::nTrackParams]);

__device__ bool quadraticFitX_proto(
  const SciFi::Hits& scifi_hits,
  int* coordToFit,
  int& n_coordToFit,
  float trackParameters[SciFi::Tracking::nTrackParams],
  const bool xFit);

}
