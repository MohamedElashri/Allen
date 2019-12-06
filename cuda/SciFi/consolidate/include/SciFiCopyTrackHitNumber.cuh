#pragma once

#include "SciFiEventModel.cuh"
#include "SciFiConsolidated.cuh"
#include "SciFiDefinitions.cuh"
#include "States.cuh"
#include "GpuAlgorithm.cuh"
#include "ArgumentsSciFi.cuh"
#include "ArgumentsUT.cuh"
#include "LookingForwardConstants.cuh"

__global__ void scifi_copy_track_hit_number(
  const SciFi::TrackHits* dev_tracks,
  uint* dev_atomics_storage,
  uint* dev_scifi_track_hit_number);

struct scifi_copy_track_hit_number_t : public GpuAlgorithm {
  constexpr static auto name {"scifi_copy_track_hit_number_t"};
  decltype(gpu_function(scifi_copy_track_hit_number)) function {scifi_copy_track_hit_number};
  using Arguments = std::tuple<dev_tracks, dev_atomics_ut, dev_scifi_track_hit_number>;

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
