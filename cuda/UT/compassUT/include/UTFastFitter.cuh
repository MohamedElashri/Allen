#pragma once


__host__ __device__
float fastfitter(
  BestParams best_params, 
  const MiniState& velo_state, 
  float improvedParams[4], 
  const float qpxz2p,
  const float* ut_dxDy);
