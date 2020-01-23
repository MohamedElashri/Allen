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
    DEVICE_OUTPUT(dev_accepted_velo_tracks_t, bool);
    DEVICE_INPUT(dev_offsets_all_velo_tracks_t, uint) dev_offsets_all_velo_tracks;
    DEVICE_INPUT(dev_tracks_t, Velo::TrackHits) dev_tracks;
    DEVICE_INPUT(dev_offsets_velo_track_hit_number_t, uint) dev_offsets_velo_track_hit_number;
    DEVICE_INPUT(dev_sorted_velo_cluster_container_t, uint) dev_sorted_velo_cluster_container;
    DEVICE_INPUT(dev_offsets_estimated_input_size_t, uint) dev_offsets_estimated_input_size;
    DEVICE_OUTPUT(dev_velo_states_t, char) dev_velo_states;
    DEVICE_INPUT(dev_three_hit_tracks_output_t, Velo::TrackletHits) dev_three_hit_tracks_output;
    DEVICE_INPUT(dev_offsets_number_of_three_hit_tracks_filtered_t, uint) dev_offsets_number_of_three_hit_tracks_filtered;
    DEVICE_OUTPUT(dev_velo_track_hits_t, char) dev_velo_track_hits;
    PROPERTY(block_dim_t, DeviceDimensions, "block_dim", "block dimensions", {256, 1, 1});
  };

  __global__ void velo_consolidate_tracks(Parameters);

  template<typename T, char... S>
  struct velo_consolidate_tracks_t : public DeviceAlgorithm, Parameters {
    constexpr static auto name = Name<S...>::s;
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
          Velo::Consolidated::states_number_of_arrays * sizeof(uint32_t));
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
      function(dim3(value<host_number_of_selected_events_t>(arguments)), property<block_dim_t>(), cuda_stream)(
        Parameters {
          begin<dev_offsets_all_velo_tracks_t>(arguments),
          begin<dev_tracks_t>(arguments),
          begin<dev_offsets_velo_track_hit_number_t>(arguments),
          begin<dev_sorted_velo_cluster_container_t>(arguments),
          begin<dev_offsets_estimated_input_size_t>(arguments),
          begin<dev_velo_states_t>(arguments),
          begin<dev_three_hit_tracks_output_t>(arguments),
          begin<dev_offsets_number_of_three_hit_tracks_filtered_t>(arguments),
          begin<dev_velo_track_hits_t>(arguments),
        });

      // Set all found tracks to accepted
      cudaCheck(cudaMemsetAsync(
        begin<dev_accepted_velo_tracks_t>(arguments), 1, size<dev_accepted_velo_tracks_t>(arguments), cuda_stream));

      if (runtime_options.do_check) {
        // Transmission device to host
        // Velo tracks
        cudaCheck(cudaMemcpyAsync(
          host_buffers.host_atomics_velo,
          begin<dev_offsets_all_velo_tracks_t>(arguments),
          size<dev_offsets_all_velo_tracks_t>(arguments),
          cudaMemcpyDeviceToHost,
          cuda_stream));

        cudaCheck(cudaMemcpyAsync(
          host_buffers.host_velo_track_hit_number,
          begin<dev_offsets_velo_track_hit_number_t>(arguments),
          size<dev_offsets_velo_track_hit_number_t>(arguments),
          cudaMemcpyDeviceToHost,
          cuda_stream));

        cudaCheck(cudaMemcpyAsync(
          host_buffers.host_velo_track_hits,
          begin<dev_velo_track_hits_t>(arguments),
          size<dev_velo_track_hits_t>(arguments),
          cudaMemcpyDeviceToHost,
          cuda_stream));
      }
    }

  private:
    Property<block_dim_t> m_block_dim {this};
  };
} // namespace velo_consolidate_tracks