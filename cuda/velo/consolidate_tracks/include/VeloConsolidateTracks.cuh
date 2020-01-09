#pragma once

#include "VeloEventModel.cuh"
#include "VeloConsolidated.cuh"
#include "States.cuh"
#include "Common.h"
#include "DeviceAlgorithm.cuh"
#include <cstdint>

namespace velo_consolidate_tracks {
  struct Parameters {
    HOST_INPUT(host_accumulated_number_of_hits_in_velo_tracks_t, uint);
    HOST_INPUT(host_number_of_reconstructed_velo_tracks_t, uint);
    HOST_INPUT(host_number_of_three_hit_tracks_filtered_t, uint);
    HOST_INPUT(host_number_of_selected_events_t, uint);
    DEVICE_OUTPUT(dev_accepted_velo_tracks_t, uint);
    DEVICE_INPUT(dev_atomics_velo_t, uint) dev_atomics_velo;
    DEVICE_INPUT(dev_tracks_t, Velo::TrackHits) dev_tracks;
    DEVICE_INPUT(dev_velo_track_hit_number_t, uint) dev_velo_track_hit_number;
    DEVICE_INPUT(dev_sorted_velo_cluster_container_t, uint) dev_sorted_velo_cluster_container;
    DEVICE_INPUT(dev_offsets_estimated_input_size_t, uint) dev_offsets_estimated_input_size;
    DEVICE_OUTPUT(dev_velo_states_t, char) dev_velo_states;
    DEVICE_INPUT(dev_three_hit_tracks_output_t, Velo::TrackletHits) dev_three_hit_tracks_output;
    DEVICE_INPUT(dev_offsets_number_of_three_hit_tracks_filtered_t, uint) dev_offsets_number_of_three_hit_tracks_filtered;
    DEVICE_OUTPUT(dev_velo_track_hits_t, char) dev_velo_track_hits;
  };

  __global__ void velo_consolidate_tracks(Parameters);

  template<typename T>
  struct velo_consolidate_tracks_t : public DeviceAlgorithm, Parameters {
    constexpr static auto name {"velo_consolidate_tracks_t"};
    decltype(global_function(velo_consolidate_tracks)) function {velo_consolidate_tracks};

    void set_arguments_size(
      ArgumentRefManager<T> arguments,
      const RuntimeOptions& runtime_options,
      const Constants& constants,
      const HostBuffers& host_buffers) const {
      set_size<dev_velo_track_hits_t>(
        arguments, value<host_accumulated_number_of_hits_in_velo_tracks_t>(arguments) * sizeof(Velo::Hit));
      set_size<dev_velo_states_t>(
        arguments,
        (value<host_number_of_reconstructed_velo_tracks_t>(arguments) +
         value<host_number_of_three_hit_tracks_filtered_t>(arguments)) *
          sizeof(VeloState));
      set_size<dev_accepted_velo_tracks_t>(
        arguments,
        value<host_number_of_reconstructed_velo_tracks_t>(arguments) +
          value<host_number_of_three_hit_tracks_filtered_t>(arguments));
    }

    void operator()(
      const ArgumentRefManager<T>& arguments,
      const RuntimeOptions& runtime_options,
      const Constants& constants,
      HostBuffers& host_buffers,
      cudaStream_t& cuda_stream,
      cudaEvent_t& cuda_generic_event) const {
      function(dim3(value<host_number_of_selected_events_t>(arguments)), block_dimension(), cuda_stream)(
        Parameters {
          offset<dev_atomics_velo_t>(arguments),
          offset<dev_tracks_t>(arguments),
          offset<dev_velo_track_hit_number_t>(arguments),
          offset<dev_sorted_velo_cluster_container_t>(arguments),
          offset<dev_offsets_estimated_input_size_t>(arguments),
          offset<dev_velo_states_t>(arguments),
          offset<dev_three_hit_tracks_output_t>(arguments),
          offset<dev_offsets_number_of_three_hit_tracks_filtered_t>(arguments),
          offset<dev_velo_track_hits_t>(arguments),
        });

      // Set all found tracks to accepted
      cudaCheck(cudaMemsetAsync(
        offset<dev_accepted_velo_tracks_t>(arguments), 1, size<dev_accepted_velo_tracks_t>(arguments), cuda_stream));

      if (runtime_options.do_check) {
        // Transmission device to host
        // Velo tracks
        cudaCheck(cudaMemcpyAsync(
          host_buffers.host_atomics_velo,
          offset<dev_atomics_velo_t>(arguments),
          size<dev_atomics_velo_t>(arguments),
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
          size<dev_velo_track_hits_t>(arguments),
          cudaMemcpyDeviceToHost,
          cuda_stream));
      }
    }
  };
} // namespace velo_consolidate_tracks