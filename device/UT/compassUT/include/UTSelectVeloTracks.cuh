#pragma once

#include "UTDefinitions.cuh"
#include "UTMagnetToolDefinitions.h"
#include "CompassUTDefinitions.cuh"
#include "DeviceAlgorithm.cuh"

namespace ut_select_velo_tracks {
  struct Parameters {
    HOST_INPUT(host_number_of_selected_events_t, uint);
    HOST_INPUT(host_number_of_reconstructed_velo_tracks_t, uint);
    DEVICE_INPUT(dev_offsets_all_velo_tracks_t, uint) dev_atomics_velo;
    DEVICE_INPUT(dev_offsets_velo_track_hit_number_t, uint) dev_velo_track_hit_number;
    DEVICE_INPUT(dev_velo_states_t, char) dev_velo_states;
    DEVICE_INPUT(dev_accepted_velo_tracks_t, bool) dev_accepted_velo_tracks;
    DEVICE_OUTPUT(dev_ut_number_of_selected_velo_tracks_t, uint) dev_ut_number_of_selected_velo_tracks;
    DEVICE_OUTPUT(dev_ut_selected_velo_tracks_t, uint) dev_ut_selected_velo_tracks;
    PROPERTY(block_dim_t, DeviceDimensions, "block_dim", "block dimensions");
  };

  __device__ bool velo_track_in_UTA_acceptance(const MiniState& state);

  __global__ void ut_select_velo_tracks(Parameters);

  template<typename T, char... S>
  struct ut_select_velo_tracks_t : public DeviceAlgorithm, Parameters {
    constexpr static auto name = Name<S...>::s;
    decltype(global_function(ut_select_velo_tracks)) function {ut_select_velo_tracks};

    void set_arguments_size(
      ArgumentRefManager<T> arguments,
      const RuntimeOptions&,
      const Constants&,
      const HostBuffers&) const
    {
      set_size<dev_ut_number_of_selected_velo_tracks_t>(arguments, value<host_number_of_selected_events_t>(arguments));
      set_size<dev_ut_selected_velo_tracks_t>(arguments, value<host_number_of_reconstructed_velo_tracks_t>(arguments));
    }

    void operator()(
      const ArgumentRefManager<T>& arguments,
      const RuntimeOptions&,
      const Constants&,
      HostBuffers&,
      cudaStream_t& cuda_stream,
      cudaEvent_t&) const
    {
      initialize<dev_ut_number_of_selected_velo_tracks_t>(arguments, 0, cuda_stream);

      function(dim3(value<host_number_of_selected_events_t>(arguments)), property<block_dim_t>(), cuda_stream)(
        Parameters {begin<dev_offsets_all_velo_tracks_t>(arguments),
                    begin<dev_offsets_velo_track_hit_number_t>(arguments),
                    begin<dev_velo_states_t>(arguments),
                    begin<dev_accepted_velo_tracks_t>(arguments),
                    begin<dev_ut_number_of_selected_velo_tracks_t>(arguments),
                    begin<dev_ut_selected_velo_tracks_t>(arguments)});
    }

  private:
    Property<block_dim_t> m_block_dim {this, {{256, 1, 1}}};
  };
} // namespace ut_select_velo_tracks