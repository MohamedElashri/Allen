#pragma once

#include "VeloEventModel.cuh"
#include "DeviceAlgorithm.cuh"
#include "States.cuh"

namespace velo_three_hit_tracks_filter {
  struct Arguments {
    HOST_INPUT(host_number_of_selected_events_t, uint);
    DEVICE_INPUT(dev_sorted_velo_cluster_container_t, uint) dev_sorted_velo_cluster_container;
    DEVICE_INPUT(dev_offsets_estimated_input_size_t, uint) dev_offsets_estimated_input_size;
    DEVICE_INPUT(dev_three_hit_tracks_input_t, Velo::TrackletHits) dev_three_hit_tracks_input;
    DEVICE_INPUT(dev_atomics_velo_t, uint) dev_atomics_velo;
    DEVICE_INPUT(dev_hit_used_t, bool) dev_hit_used;
    DEVICE_OUTPUT(dev_three_hit_tracks_output_t, Velo::TrackletHits) dev_three_hit_tracks_output;
    DEVICE_OUTPUT(dev_number_of_three_hit_tracks_output_t, uint) dev_number_of_three_hit_tracks_output;
  };

  __global__ void velo_three_hit_tracks_filter(Arguments);

  template<typename T>
  struct velo_three_hit_tracks_filter_t : public DeviceAlgorithm, Arguments {
    constexpr static auto name {"velo_three_hit_tracks_filter_t"};
    decltype(global_function(velo_three_hit_tracks_filter)) function {velo_three_hit_tracks_filter};

    void set_arguments_size(
      ArgumentRefManager<T> arguments,
      const RuntimeOptions& runtime_options,
      const Constants& constants,
      const HostBuffers& host_buffers) const {
      set_size<dev_number_of_three_hit_tracks_output_t>(arguments, value<host_number_of_selected_events_t>(arguments));
      set_size<dev_three_hit_tracks_output_t>(
        arguments, value<host_number_of_selected_events_t>(arguments) * Velo::Constants::max_tracks);
    }

    void operator()(
      const ArgumentRefManager<T>& arguments,
      const RuntimeOptions& runtime_options,
      const Constants& constants,
      HostBuffers& host_buffers,
      cudaStream_t& cuda_stream,
      cudaEvent_t& cuda_generic_event) const {
      cudaCheck(cudaMemsetAsync(
        offset<dev_number_of_three_hit_tracks_output_t>(arguments),
        0,
        size<dev_number_of_three_hit_tracks_output_t>(arguments),
        cuda_stream));

      function(dim3(value<host_number_of_selected_events_t>(arguments)), block_dimension(), cuda_stream)(
        Arguments {
          offset<dev_sorted_velo_cluster_container_t>(arguments),
          offset<dev_offsets_estimated_input_size_t>(arguments),
          offset<dev_three_hit_tracks_input_t>(arguments),
          offset<dev_atomics_velo_t>(arguments),
          offset<dev_hit_used_t>(arguments),
          offset<dev_three_hit_tracks_output_t>(arguments),
          offset<dev_number_of_three_hit_tracks_output_t>(arguments)
        });
    }
  };
} // namespace velo_three_hit_tracks_filter