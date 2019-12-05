#pragma once

#include "VeloEventModel.cuh"
#include "VeloConsolidated.cuh"
#include "States.cuh"
#include "Common.h"
#include "GpuAlgorithm.cuh"
#include "ArgumentsCommon.cuh"
#include "ArgumentsVelo.cuh"
#include <cstdint>

__global__ void velo_consolidate_tracks(
  uint* dev_atomics_velo,
  const Velo::TrackHits* dev_tracks,
  uint* dev_velo_track_hit_number,
  uint* dev_velo_cluster_container,
  uint* dev_module_cluster_start,
  char* dev_velo_track_hits,
  char* dev_velo_states);

struct velo_consolidate_tracks_t : public GpuAlgorithm {
  constexpr static auto name {"velo_consolidate_tracks_t"};
  decltype(gpu_function(velo_consolidate_tracks)) algorithm {velo_consolidate_tracks};
  using Arguments = std::tuple<
    dev_atomics_velo,
    dev_tracks,
    dev_velo_track_hit_number,
    dev_velo_cluster_container,
    dev_estimated_input_size,
    dev_velo_track_hits,
    dev_velo_states,
    dev_accepted_velo_tracks>;

  void set_arguments_size(
    ArgumentRefManager<Arguments> arguments,
    const RuntimeOptions& runtime_options,
    const Constants& constants,
    const HostBuffers& host_buffers) const;

  void visit(
    const ArgumentRefManager<Arguments>& arguments,
    const RuntimeOptions& runtime_options,
    const Constants& constants,
    HostBuffers& host_buffers,
    cudaStream_t& cuda_stream,
    cudaEvent_t& cuda_generic_event) const;
};
