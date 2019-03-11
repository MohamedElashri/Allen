#pragma once

#include "MiniState.cuh"
#include "CompassUTDefinitions.cuh"
#include "PrVeloUTDefinitions.cuh"
#include "UTEventModel.cuh"

__host__ __device__

float fastfitter(
  const BestParams best_params, 
  const MiniState& velo_state, 
  const int best_hits[UT::Constants::n_layers],
  const float qpxz2p,
  const float* ut_dxDy,
  const UT::Hits& ut_hits,
  float improvedParams[4]);
