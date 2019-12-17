#pragma once

#include "VeloEventModel.cuh"
#include "VeloConsolidated.cuh"
#include "States.cuh"
#include "Common.h"
#include "GpuAlgorithm.cuh"
#include <cstdint>

namespace velo_consolidate_tracks {
  // Arguments
  HOST_INPUT(host_accumulated_number_of_hits_in_velo_tracks_t, uint)
  HOST_INPUT(host_number_of_reconstructed_velo_tracks_t, uint)
  HOST_INPUT(host_number_of_selected_events_t, uint)
  DEVICE_INPUT(dev_atomics_velo_t, uint)
  DEVICE_INPUT(dev_tracks_t, Velo::TrackHits)
  DEVICE_INPUT(dev_velo_track_hit_number_t, uint)
  DEVICE_INPUT(dev_velo_cluster_container_t, uint)
  DEVICE_INPUT(dev_estimated_input_size_t, uint)
  DEVICE_INPUT(dev_velo_states_t, char)
  DEVICE_OUTPUT(dev_accepted_velo_tracks_t, uint)
  DEVICE_OUTPUT(dev_velo_track_hits_t, char)

  __global__ void velo_consolidate_tracks(
    dev_atomics_velo_t dev_atomics_velo,
    dev_tracks_t dev_tracks,
    dev_velo_track_hit_number_t dev_velo_track_hit_number,
    dev_velo_cluster_container_t dev_velo_cluster_container,
    dev_estimated_input_size_t dev_estimated_input_size,
    dev_velo_track_hits_t dev_velo_track_hits,
    dev_velo_states_t dev_velo_states);

  template<typename Arguments>
  struct velo_consolidate_tracks_t : public DeviceAlgorithm {
    constexpr static auto name {"velo_consolidate_tracks_t"};
    decltype(global_function(velo_consolidate_tracks)) function {velo_consolidate_tracks};

    void set_arguments_size(
      ArgumentRefManager<Arguments> arguments,
      const RuntimeOptions& runtime_options,
      const Constants& constants,
      const HostBuffers& host_buffers) const {
      set_size<dev_velo_track_hits_t>(
        arguments, offset<host_accumulated_number_of_hits_in_velo_tracks_t>(arguments)[0] * sizeof(Velo::Hit));
      set_size<dev_velo_states_t>(
        arguments, offset<host_number_of_reconstructed_velo_tracks_t>(arguments)[0] * sizeof(VeloState));
      set_size<dev_accepted_velo_tracks_t>(
        arguments, offset<host_number_of_reconstructed_velo_tracks_t>(arguments)[0]);
    }

    void operator()(
      const ArgumentRefManager<Arguments>& arguments,
      const RuntimeOptions& runtime_options,
      const Constants& constants,
      HostBuffers& host_buffers,
      cudaStream_t& cuda_stream,
      cudaEvent_t& cuda_generic_event) const {
      function.invoke(dim3(offset<host_number_of_selected_events_t>(arguments)[0]), block_dimension(), cuda_stream)(
        offset<dev_atomics_velo_t>(arguments),
        offset<dev_tracks_t>(arguments),
        offset<dev_velo_track_hit_number_t>(arguments),
        offset<dev_velo_cluster_container_t>(arguments),
        offset<dev_estimated_input_size_t>(arguments),
        offset<dev_velo_track_hits_t>(arguments),
        offset<dev_velo_states_t>(arguments));

      // Set all found tracks to accepted
      cudaCheck(cudaMemsetAsync(
        offset<dev_accepted_velo_tracks_t>(arguments), 1, size<dev_accepted_velo_tracks_t>(arguments), cuda_stream));

      if (runtime_options.do_check) {
        // Transmission device to host
        // Velo tracks
        cudaCheck(cudaMemcpyAsync(
          host_buffers.host_atomics_velo,
          offset<dev_atomics_velo_t>(arguments),
          (2 * offset<host_number_of_selected_events_t>(arguments)[0] + 1) * sizeof(uint),
          cudaMemcpyDeviceToHost,
          cuda_stream));

        cudaCheck(cudaMemcpyAsync(
          host_buffers.host_velo_track_hit_number,
          offset<dev_velo_track_hit_number_t>(arguments),
          size<dev_velo_track_hit_number_t>(arguments),
          cudaMemcpyDeviceToHost,
          cuda_stream));

        cudaCheck(cudaMemcpyAsync(
          host_buffers.host_velo_track_hits,
          offset<dev_velo_track_hits_t>(arguments),
          offset<host_accumulated_number_of_hits_in_velo_tracks_t>(arguments)[0] * sizeof(Velo::Hit),
          cudaMemcpyDeviceToHost,
          cuda_stream));
      }
    }
  };
} // namespace velo_consolidate_tracks