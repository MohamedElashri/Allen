#pragma once

#include "UTEventModel.cuh"
#include "UTDefinitions.cuh"
#include "CompassUTDefinitions.cuh"
#include <tuple>

namespace compass_ut {
  __device__ std::tuple<int, int, int, int, BestParams> find_best_hits(
    const short* win_size_shared,
    UT::ConstHits& ut_hits,
    const UT::HitOffsets& ut_hit_offsets,
    const MiniState& velo_state,
    const float* ut_dxDy,
    const unsigned max_considered_before_found,
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

  __device__ int sum_layer_hits(const TrackCandidates& ranges, const int layer0, const int layer2);

  __device__ int sum_layer_hits(const TrackCandidates& ranges, const int layer);

  __device__ int
  calc_index(const int i, const TrackCandidates& ranges, const int layer, const UT::HitOffsets& ut_hit_offsets);

  __device__ int calc_index(
    const int i,
    const TrackCandidates& ranges,
    const int layer0,
    const int layer2,
    const UT::HitOffsets& ut_hit_offsets);

  __device__ void compass_ut_tracking(
    const short* dev_windows_layers,
    const unsigned number_of_tracks_event,
    const int i_track,
    const unsigned current_track_offset,
    Velo::Consolidated::ConstStates& velo_states,
    UT::ConstHits& ut_hits,
    const UT::HitOffsets& ut_hit_offsets,
    const float* bdl_table,
    const float* dev_ut_dxDy,
    const float magnet_polarity,
    short* win_size_shared,
    unsigned* n_veloUT_tracks_event,
    UT::TrackHits* veloUT_tracks_event,
    const int event_hit_offset,
    const float min_momentum_final,
    const float min_pt_final,
    const unsigned max_considered_before_found,
    const float delta_tx_2,
    const float hit_tol_2,
    const float sigma_velo_slope);

  __host__ __device__ bool velo_track_in_UT_acceptance(const MiniState& state);

  __device__ void fill_shared_windows(
    const short* windows_layers,
    const int number_of_tracks_event,
    const int i_track,
    short* win_size_shared);

  __device__ void save_track(
    const int i_track,
    const float* bdlTable,
    const MiniState& velo_state,
    const BestParams& best_params,
    const int* best_hits,
    UT::ConstHits& ut_hits,
    const float* ut_dxDy,
    const float magSign,
    unsigned* n_veloUT_tracks,
    UT::TrackHits* VeloUT_tracks,
    const int event_hit_offset,
    const float min_momentum_final,
    const float min_pt_final);

  __host__ __device__ int master_index(const int index1, const int index2, const int index3);
} // namespace compass_ut
