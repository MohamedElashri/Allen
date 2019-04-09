#pragma once

#include "Common.h"
#include "LookingForwardConstants.cuh"
#include "SciFiEventModel.cuh"
#include "TrackUtils.cuh"

namespace LookingForward {

  struct fitSums {
    float s0[LookingForward::num_threads_fit];
    float sz[LookingForward::num_threads_fit];
    float sz2[LookingForward::num_threads_fit];
    float sz3[LookingForward::num_threads_fit];
    float sz4[LookingForward::num_threads_fit];
    float sd[LookingForward::num_threads_fit];
    float sdz[LookingForward::num_threads_fit];
    float sdz2[LookingForward::num_threads_fit];
  };

__device__ float linear_parameterization(
  const float p0,
  const float p1,
  const float z);

__device__ void fitParabola_parallel(
  const SciFi::Hits& scifi_hits,
  const uint16_t* coordToFit,
  const uint event_offset, 
  const uint8_t n_coordToFit,
  LookingForward::fitSums& fit_sums,
  float trackParameters[SciFi::Tracking::nTrackParams],
  const bool xFit);

__device__ int fitParabola_proto(
  const SciFi::Hits& scifi_hits,
  const uint16_t* coordToFit,
  const uint event_offset, 
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

__device__ void get_average_x_at_reference_plane(
  const uint16_t* hits,
  const uint event_offset,
  const uint8_t n_hits,
  const SciFi::Hits& scifi_hits,
  const float xAtRef_initial,
  const SciFi::Tracking::Arrays* constArrays,
  const MiniState& velo_state,
  const float zMagSlope,
  float* xAtRefAverage);

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
  const uint16_t* uv_hits,
  const uint event_offset, 
  const uint8_t n_uv_hits,
  const SciFi::Hits& scifi_hits,
  float trackParams[SciFi::Tracking::nTrackParams]);

__device__ bool quadraticFitX_proto(
  const SciFi::Hits& scifi_hits,
  const uint16_t* coordToFit,
  const uint event_offset, 
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
