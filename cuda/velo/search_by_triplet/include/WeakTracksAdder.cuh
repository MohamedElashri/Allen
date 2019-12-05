#pragma once

#include "VeloEventModel.cuh"
#include "GpuAlgorithm.cuh"
#include "ArgumentsVelo.cuh"
#include "States.cuh"

__device__ void weak_tracks_adder_impl(
  uint* weaktracks_insert_pointer,
  uint* tracks_insert_pointer,
  Velo::TrackletHits* weak_tracks,
  Velo::TrackHits* tracks,
  bool* hit_used,
  const float* hit_Xs,
  const float* hit_Ys,
  const float* hit_Zs);

__global__ void velo_weak_tracks_adder(
  uint32_t* dev_velo_cluster_container,
  uint* dev_module_cluster_start,
  Velo::TrackHits* dev_tracks,
  Velo::TrackletHits* dev_weak_tracks,
  bool* dev_hit_used,
  uint* dev_atomics_velo);

struct velo_weak_tracks_adder_t : public GpuAlgorithm {
  constexpr static auto name {"velo_weak_tracks_adder_t"};
  decltype(gpu_function(velo_weak_tracks_adder)) algorithm {velo_weak_tracks_adder};
  using Arguments = std::tuple<
    dev_velo_cluster_container,
    dev_estimated_input_size,
    dev_tracks,
    dev_weak_tracks,
    dev_hit_used,
    dev_atomics_velo>;

  void set_arguments_size(
    ArgumentRefManager<Arguments> arguments,
    const RuntimeOptions& runtime_options,
    const Constants& constants,
    const HostBuffers& host_buffers) const {}

  void visit(
    const ArgumentRefManager<Arguments>& arguments,
    const RuntimeOptions& runtime_options,
    const Constants& constants,
    HostBuffers& host_buffers,
    cudaStream_t& cuda_stream,
    cudaEvent_t& cuda_generic_event) const;
};
