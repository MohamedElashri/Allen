#pragma once

#include "VeloEventModel.cuh"
#include "DeviceAlgorithm.cuh"
#include "States.cuh"

namespace velo_three_hit_tracks_filter {
  struct Parameters {
    HOST_INPUT(host_number_of_selected_events_t, uint);
    DEVICE_INPUT(dev_sorted_velo_cluster_container_t, char) dev_sorted_velo_cluster_container;
    DEVICE_INPUT(dev_offsets_estimated_input_size_t, uint) dev_offsets_estimated_input_size;
    DEVICE_INPUT(dev_three_hit_tracks_input_t, Velo::TrackletHits) dev_three_hit_tracks_input;
    DEVICE_INPUT(dev_atomics_velo_t, uint) dev_atomics_velo;
    DEVICE_INPUT(dev_hit_used_t, bool) dev_hit_used;
    DEVICE_OUTPUT(dev_three_hit_tracks_output_t, Velo::TrackletHits) dev_three_hit_tracks_output;
    DEVICE_OUTPUT(dev_number_of_three_hit_tracks_output_t, uint) dev_number_of_three_hit_tracks_output;

    // Max chi2
    PROPERTY(max_chi2_t, float, "max_chi2", "chi2") max_chi2;

    // Maximum number of tracks to follow at a time
    PROPERTY(max_weak_tracks_t, uint, "max_weak_tracks", "max weak tracks") max_weak_tracks;
    PROPERTY(block_dim_t, DeviceDimensions, "block_dim", "block dimensions");
  };

  __global__ void velo_three_hit_tracks_filter(Parameters);

  template<typename T>
  struct velo_three_hit_tracks_filter_t : public DeviceAlgorithm, Parameters {

    decltype(global_function(velo_three_hit_tracks_filter)) function {velo_three_hit_tracks_filter};

    void set_arguments_size(
      ArgumentRefManager<T> arguments,
      const RuntimeOptions&,
      const Constants&,
      const HostBuffers&) const
    {
      set_size<dev_number_of_three_hit_tracks_output_t>(arguments, value<host_number_of_selected_events_t>(arguments));
      set_size<dev_three_hit_tracks_output_t>(
        arguments, value<host_number_of_selected_events_t>(arguments) * Velo::Constants::max_tracks);
    }

    void operator()(
      const ArgumentRefManager<T>& arguments,
      const RuntimeOptions&,
      const Constants&,
      HostBuffers&,
      cudaStream_t& cuda_stream,
      cudaEvent_t&) const
    {
      initialize<dev_number_of_three_hit_tracks_output_t>(arguments, 0, cuda_stream);

      function(dim3(value<host_number_of_selected_events_t>(arguments)), property<block_dim_t>(), cuda_stream)(
        Parameters {begin<dev_sorted_velo_cluster_container_t>(arguments),
                    begin<dev_offsets_estimated_input_size_t>(arguments),
                    begin<dev_three_hit_tracks_input_t>(arguments),
                    begin<dev_atomics_velo_t>(arguments),
                    begin<dev_hit_used_t>(arguments),
                    begin<dev_three_hit_tracks_output_t>(arguments),
                    begin<dev_number_of_three_hit_tracks_output_t>(arguments),
                    property<max_chi2_t>(),
                    property<max_weak_tracks_t>()});
    }

  private:
    Property<max_chi2_t> m_chi2 {this, 20.0f};
    Property<max_weak_tracks_t> m_max_weak {this, 500u};
    Property<block_dim_t> m_block_dim {this, {{256, 1, 1}}};
  };
} // namespace velo_three_hit_tracks_filter