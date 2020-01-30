#pragma once

#include "UTEventModel.cuh"
#include "UTDefinitions.cuh"
#include "CompassUTDefinitions.cuh"
#include "FindBestHits.cuh"
#include <tuple>

__device__ std::tuple<int, int, int, int, BestParams> find_best_hits(
  const short* win_size_shared,
  UT::ConstHits& ut_hits,
  const UT::HitOffsets& ut_hit_offsets,
  const MiniState& velo_state,
  const float* ut_dxDy,
  const uint max_considered_before_found,
  const float delta_tx_2,
  const float hit_tol_2,
  const float sigma_velo_slope,
  const float inv_sigma_velo_slope,
  const int event_hit_offset);

__device__ BestParams pkick_fit(
  const int best_hits[UT::Constants::n_layers],
  UT::ConstHits& ut_hits,
  const MiniState& velo_state,
  const float* ut_dxDy,
  const float yyProto,
  const bool forward,
  const float sigma_velo_slope,
  const float inv_sigma_velo_slope);

__device__ __inline__ int sum_layer_hits(const TrackCandidates& ranges, const int layer0, const int layer2);

__device__ __inline__ int sum_layer_hits(const TrackCandidates& ranges, const int layer);

__device__ __inline__ int
calc_index(const int i, const TrackCandidates& ranges, const int layer, const UT::HitOffsets& ut_hit_offsets);

__device__ __inline__ int calc_index(
  const int i,
  const TrackCandidates& ranges,
  const int layer0,
  const int layer2,
  const UT::HitOffsets& ut_hit_offsets);
