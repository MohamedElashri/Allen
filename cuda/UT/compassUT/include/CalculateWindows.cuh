#pragma once

#include "CudaCommon.h"
#include "UTDefinitions.cuh"
#include "UTMagnetToolDefinitions.h"
#include "VeloConsolidated.cuh"
#include "UTEventModel.cuh"
#include "States.cuh"
#include "UTMagnetToolDefinitions.h"
#include <tuple>

__device__ bool velo_track_in_UTA_acceptance(const MiniState& state);

__device__ std::tuple<int, int, int, int, int, int, int, int, int, int> calculate_windows(
  const int layer,
  const MiniState& velo_state,
  const float* fudge_factors,
  UT::ConstHits& ut_hits,
  const UT::HitOffsets& ut_hit_count,
  const float* ut_dxDy,
  const float* dev_unique_sector_xs,
  const uint* dev_unique_x_sector_layer_offsets,
  const float y_tol,
  const float y_tol_slope,
  const float min_pt,
  const float min_momentum);

__device__ std::tuple<int, int> find_candidates_in_sector_group(
  UT::ConstHits& ut_hits,
  const UT::HitOffsets& ut_hit_offsets,
  const MiniState& velo_state,
  const float* dev_unique_sector_xs,
  const float x_track,
  const float y_track,
  const float dx_dy,
  const float invNormFact,
  const float xTol,
  const int sector_group,
  const float y_tol,
  const float y_tol_slope);

__device__ void tol_refine(
  int& first_candidate,
  int& last_candidate,
  UT::ConstHits& ut_hits,
  const MiniState& velo_state,
  const float invNormfact,
  const float xTolNormFact,
  const float dxDy,
  const float y_tol,
  const float y_tol_slope);
