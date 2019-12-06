#pragma once

#include "VeloEventModel.cuh"
#include "UTDefinitions.cuh"
#include "UTEventModel.cuh"
#include "UTConsolidated.cuh"
#include "GpuAlgorithm.cuh"
#include "ArgumentsCommon.cuh"
#include "ArgumentsVelo.cuh"
#include "ArgumentsUT.cuh"

__global__ void ut_copy_track_hit_number(
  const UT::TrackHits* dev_tracks,
  uint* dev_atomics_storage,
  uint* dev_ut_track_hit_number);

struct ut_copy_track_hit_number_t : public GpuAlgorithm {
  constexpr static auto name {"ut_copy_track_hit_number_t"};
  decltype(gpu_function(ut_copy_track_hit_number)) function {ut_copy_track_hit_number};
  using Arguments = std::tuple<dev_ut_tracks, dev_atomics_ut, dev_ut_track_hit_number>;

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
