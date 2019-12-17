#pragma once

#include "VeloEventModel.cuh"
#include "GpuAlgorithm.cuh"
#include "States.cuh"

namespace velo_weak_tracks_adder {
  // Arguments
  struct dev_velo_cluster_container_t : input_datatype<uint> {};
  struct dev_estimated_input_size_t : input_datatype<uint> {};
  struct dev_tracks_t : output_datatype<Velo::TrackHits> {};
  struct dev_weak_tracks_t : output_datatype<Velo::TrackletHits> {};
  struct dev_hit_used_t : output_datatype<bool> {};
  struct dev_atomics_velo_t : output_datatype<uint> {};

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
    dev_velo_cluster_container_t dev_velo_cluster_container,
    dev_estimated_input_size_t dev_estimated_input_size,
    dev_tracks_t dev_tracks,
    dev_weak_tracks_t dev_weak_tracks,
    dev_hit_used_t dev_hit_used,
    dev_atomics_velo_t dev_atomics_velo);

  template<typename Arguments>
  struct velo_weak_tracks_adder_t : public GpuAlgorithm {
    constexpr static auto name {"velo_weak_tracks_adder_t"};
    decltype(gpu_function(velo_weak_tracks_adder)) function {velo_weak_tracks_adder};

    void set_arguments_size(
      ArgumentRefManager<Arguments> arguments,
      const RuntimeOptions& runtime_options,
      const Constants& constants,
      const HostBuffers& host_buffers) const {}

    void operator()(
      const ArgumentRefManager<Arguments>& arguments,
      const RuntimeOptions& runtime_options,
      const Constants& constants,
      HostBuffers& host_buffers,
      cudaStream_t& cuda_stream,
      cudaEvent_t& cuda_generic_event) const {
      function.invoke(dim3(host_buffers.host_number_of_selected_events[0]), block_dimension(), cuda_stream)(
        offset<dev_velo_cluster_container_t>(arguments),
        offset<dev_estimated_input_size_t>(arguments),
        offset<dev_tracks_t>(arguments),
        offset<dev_weak_tracks_t>(arguments),
        offset<dev_hit_used_t>(arguments),
        offset<dev_atomics_velo_t>(arguments));
    }
  };
} // namespace velo_weak_tracks_adder