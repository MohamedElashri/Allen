#pragma once

#include "UTDefinitions.cuh"
#include "UTEventModel.cuh"
#include "UTConsolidated.cuh"
#include "GpuAlgorithm.cuh"
#include "ArgumentsUT.cuh"

__global__ void ut_consolidate_tracks(
  uint* dev_ut_hits,
  uint* dev_ut_hit_offsets,
  char* dev_ut_track_hits,
  uint* dev_atomics_ut,
  uint* dev_ut_track_hit_number,
  float* dev_ut_qop,
  float* dev_ut_x,
  float* dev_ut_tx,
  float* dev_ut_z,
  uint* dev_ut_track_velo_indices,
  const UT::TrackHits* dev_veloUT_tracks,
  const uint* dev_unique_x_sector_layer_offsets);

struct ut_consolidate_tracks_t : public GpuAlgorithm {
  constexpr static auto name {"ut_consolidate_tracks_t"};
  decltype(gpu_function(ut_consolidate_tracks)) function {ut_consolidate_tracks};
  using Arguments = std::tuple<
    dev_ut_hits,
    dev_ut_hit_offsets,
    dev_ut_track_hits,
    dev_atomics_ut,
    dev_ut_track_hit_number,
    dev_ut_x,
    dev_ut_z,
    dev_ut_tx,
    dev_ut_qop,
    dev_ut_track_velo_indices,
    dev_ut_tracks>;

  void set_arguments_size(
    ArgumentRefManager<Arguments> arguments,
    const RuntimeOptions& runtime_options,
    const Constants& constants,
    const HostBuffers& host_buffers) const;

  void operator()(
    const ArgumentRefManager<Arguments>& arguments,
    const RuntimeOptions& runtime_options,
    const Constants& constants,
    HostBuffers& host_buffers,
    cudaStream_t& cuda_stream,
    cudaEvent_t& cuda_generic_event) const;
};
