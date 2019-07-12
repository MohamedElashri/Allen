#pragma once

#include <cmath>
#include "SciFiEventModel.cuh"
#
/**
   Helper functions related to track properties
 */

// extrapolate x position from given state to z
__host__ __device__ float xFromVelo(const float z, const MiniState& velo_state);

// extrapolate y position from given state to z
__host__ __device__ float yFromVelo(const float z, const MiniState& velo_state);

__host__ __device__ float evalCubicParameterization(const float params[4], float z);

__host__ __device__ float zMagnet(const MiniState& velo_state, const SciFi::Tracking::Arrays* constArrays);

__host__ __device__ float calcDxRef(float pt, const MiniState& velo_state);

__host__ __device__ float calcqOverP(
  float bx,
  const SciFi::Tracking::Arrays* constArrays,
  const MiniState& velo_state,
  const float magnet_polarity);

__host__ __device__ float evalParameterizationX(const float* params, float z);

__host__ __device__ float evalParameterizationY(const float* params, float z);

__host__ __device__ void getTrackParameters(
  float xAtRef,
  const MiniState& velo_state,
  const SciFi::Tracking::Arrays* constArrays,
  float trackParams[SciFi::Tracking::nTrackParams]);

__host__ __device__ float
trackToHitDistance(const float trackParameters[SciFi::Tracking::nTrackParams], const SciFi::Hits& scifi_hits, int hit);
