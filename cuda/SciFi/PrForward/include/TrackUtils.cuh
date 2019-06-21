#pragma once

#include <cmath>

#include "SciFiDefinitions.cuh"
#include "PrForwardConstants.cuh"
#include "HitUtils.cuh"
#include "ParabolaFitting.cuh"
#include "SciFiEventModel.cuh"

/**
   Helper functions related to track properties
 */

// extrapolate x position from given state to z
__host__ __device__ float xFromVelo(const float z, const MiniState& velo_state);

// extrapolate y position from given state to z
__host__ __device__ float yFromVelo(const float z, const MiniState& velo_state);

__host__ __device__ float evalCubicParameterization(const float params[4], float z);

__host__ __device__ float evalParameterizationX(const float* params, float z);

__host__ __device__ float evalParameterizationY(const float* params, float z);

__host__ __device__ bool lowerByQuality(SciFi::Tracking::Track t1, SciFi::Tracking::Track t2);

__host__ __device__ inline float straightLinePropagationFromReferencePlane(const float params[4], float z)
{
  float dz = z - SciFi::Tracking::zReference;
  return params[0] + params[1] * dz;
}

__host__ __device__ inline float straightLinePropagationFromReferencePlane(const float x0, const float tx, float z)
{
  float dz = z - SciFi::Tracking::zReference;
  return x0 + tx * dz;
}

__host__ __device__ void getTrackParameters(
  float xAtRef,
  const MiniState& velo_state,
  const SciFi::Tracking::Arrays* constArrays,
  float trackParams[SciFi::Tracking::nTrackParams]);

__host__ __device__ float calcqOverP(
  float bx,
  const SciFi::Tracking::Arrays* constArrays,
  const MiniState& velo_state,
  const float magnet_polarity);

__host__ __device__ float zMagnet(const MiniState& velo_state, const SciFi::Tracking::Arrays* constArrays);

__host__ __device__ float calcDxRef(float pt, const MiniState& velo_state);

__host__ __device__ float
trackToHitDistance(const float trackParameters[SciFi::Tracking::nTrackParams], const SciFi::Hits& scifi_hits, int hit);

__host__ __device__ float chi2XHit(const float parsX[4], const SciFi::Hits& scifi_hits, const int hit);

__host__ __device__ bool quadraticFitX(
  const SciFi::Hits& scifi_hits,
  float trackParameters[SciFi::Tracking::nTrackParams],
  int coordToFit[SciFi::Tracking::max_coordToFit],
  int& n_coordToFit,
  PlaneCounter& planeCounter,
  SciFi::Tracking::HitSearchCuts& pars_cur);

__host__ __device__ bool fitYProjection(
  const SciFi::Hits& scifi_hits,
  SciFi::Tracking::Track& track,
  int stereoHits[SciFi::Tracking::max_stereo_hits],
  int& n_stereoHits,
  PlaneCounter& planeCounter,
  const MiniState& velo_state,
  const SciFi::Tracking::Arrays* constArrays,
  SciFi::Tracking::HitSearchCuts& pars_cur);
