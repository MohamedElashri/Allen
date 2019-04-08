#pragma once

#include "Common.h"
#include "LookingForwardConstants.cuh"
#include "SciFiEventModel.cuh"
#include "TrackUtils.cuh"

namespace LookingForward {

__device__ float linear_parameterization(
  const float p0,
  const float p1,
  const float z);

__device__ int fitParabola_proto(
  const SciFi::Hits& scifi_hits,
  const int* coordToFit,
  const uint8_t n_coordToFit,
  float trackParameters[SciFi::Tracking::nTrackParams],
  const bool xFit);

__device__ bool straight_line_fit_y_projection(
  const MiniState& velo_state,
  const SciFi::Tracking::Arrays* constArrays,
  const int* uv_hits,
  const uint8_t n_uv_hits,
  const SciFi::Hits& scifi_hits,
  float trackParams[SciFi::Tracking::nTrackParams]);

__device__ float get_average_x_at_reference_plane(
  const int* hits,
  const uint8_t n_hits,
  const SciFi::Hits& scifi_hits,
  const float xParams_seed_0,
  const float xParams_seed_1,
  const SciFi::Tracking::Arrays* constArrays,
  const MiniState& velo_state,
  const float zMagSlope);

__device__ int getChi2( 
  const SciFi::Hits& scifi_hits,
  const int* coordToFit,
  const uint8_t n_coordToFit,
  float trackParameters[SciFi::Tracking::nTrackParams],
  const bool xFit);

__device__ void removeOutlier_proto(
  const SciFi::Hits& scifi_hits,
  int* coordToFit,
  uint8_t& n_coordToFit,
  const int worst);

__device__ bool fitYProjection_proto(
  const MiniState& velo_state,
  const SciFi::Tracking::Arrays* constArrays,
  const int* uv_hits,
  const uint8_t n_uv_hits,
  const SciFi::Hits& scifi_hits,
  float trackParams[SciFi::Tracking::nTrackParams]);

__device__ bool quadraticFitX_proto(
  const SciFi::Hits& scifi_hits,
  int* coordToFit,
  uint8_t& n_coordToFit,
  float trackParameters[SciFi::Tracking::nTrackParams],
  const bool xFit);

__device__ bool quadratic_fit_x_with_outlier_removal(
  const SciFi::Hits& scifi_hits,
  int* coordToFit,
  int& n_coordToFit,
  float trackParameters[SciFi::Tracking::nTrackParams],
  const bool xFit);

}
