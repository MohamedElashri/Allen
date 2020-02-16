#pragma once

#include "States.cuh"
#include "UTDefinitions.cuh"
#include "CompassUTDefinitions.cuh"
#include "UTEventModel.cuh"

__device__ float eval_log_function(const int N, float& init, const float* a, const float* b);

__device__ float evaluateLinearDiscriminant(const float inputValues[3], const int nHits);

__device__ float fastfitter(
  const BestParams best_params,
  const MiniState& velo_state,
  const int best_hits[UT::Constants::n_layers],
  const float qpxz2p,
  const float* ut_dxDy,
  UT::ConstHits& ut_hits,
  float improvedParams[4]);
