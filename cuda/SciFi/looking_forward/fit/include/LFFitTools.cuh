#pragma once

#include "Common.h"
#include "LookingForwardConstants.cuh"
#include "LookingForwardTools.cuh"
#include "SciFiEventModel.cuh"
#include "TrackUtils.cuh"

namespace LookingForward {
  __device__ std::tuple<float, float, float> lms_y_fit(
    const SciFi::TrackHits& track,
    const uint number_of_uv_hits,
    const SciFi::Hits& scifi_hits,
    const float a1,
    const float b1,
    const float c1,
    const float d_ratio,
    const uint event_offset,
    const LookingForward::Constants* dev_looking_forward_constants);

  /* Calculate variables at end of SciFi, from trackParams
     given at zRef within SciFi */
  __device__ float x_at_end_scifi(const float* trackParams);

  __device__ float y_at_end_scifi(const float* trackParams);

  __device__ float tx_at_end_scifi(const float* trackParams);

  __device__ float ty_at_end_scifi(const float* trackParams);

  __device__ float linear_parameterization(const float p0, const float p1, const float z);

  __device__ float trackToHitDistance(
    const float trackParameters[SciFi::Tracking::nTrackParams],
    const float hit_x,
    const float hit_z,
    const float hit_dxdy);

  __device__ int fitParabola_proto(
    const float* hits_x,
    const float* hits_z,
    const float* hits_dxdy,
    const float* hits_w,
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

  __device__ float get_x_on_reference_plane(
    const float hit_x,
    const float hit_z,
    const float xAtRef_initial,
    const SciFi::Tracking::Arrays* constArrays,
    const MiniState& velo_state,
    const float zMagSlope);

  __device__ float get_average_x_at_reference_plane(
    const float* hits_x,
    const float* hits_z,
    const uint8_t n_hits,
    const float xAtRef_initial,
    const SciFi::Tracking::Arrays* constArrays,
    const MiniState& velo_state,
    const float zMagSlope);

  __device__ float get_average_and_individual_x_at_reference_plane(
    const float* hits_x,
    const float* hits_z,
    const uint8_t n_hits,
    const float xAtRef_initial,
    const SciFi::Tracking::Arrays* constArrays,
    const MiniState& velo_state,
    const float zMagSlope,
    float* hits_x_atRef);

  __device__ float
  get_average_x_at_reference_plane_spread(const float xAtRef_average, const float* hits_x, const int n_hits);

  __device__ float get_average_x_at_reference_plane_from_scifi_propagaion(
    const int* hits,
    const uint8_t n_hits,
    const SciFi::Hits& scifi_hits,
    const float qop);

  __device__ int getChi2(
    const float* hits_x,
    const float* hits_z,
    const float* hits_dxdy,
    const float* hits_w,
    const uint8_t n_coordToFit,
    float trackParameters[SciFi::Tracking::nTrackParams]);

  __device__ void removeOutlier_proto(int* coordToFit, uint8_t& n_coordToFit, const int worst);

  __device__ bool fitYProjection_proto(
    const MiniState& velo_state,
    const SciFi::Tracking::Arrays* constArrays,
    const int* uv_hits,
    const uint8_t n_uv_hits,
    const SciFi::Hits& scifi_hits,
    float trackParams[SciFi::Tracking::nTrackParams]);

} // namespace LookingForward
