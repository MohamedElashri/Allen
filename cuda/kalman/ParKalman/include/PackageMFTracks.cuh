#pragma once

#include "ParKalmanDefinitions.cuh"
#include "ParKalmanMath.cuh"
#include "UTConsolidated.cuh"
#include "VeloConsolidated.cuh"
#include "States.cuh"
#include "DeviceAlgorithm.cuh"

namespace package_mf_tracks {

  struct Parameters {
    DEVICE_INPUT(dev_offsets_all_velo_tracks_t, uint) dev_atomics_velo;
    DEVICE_INPUT(dev_offsets_velo_track_hit_number_t, uint) dev_velo_track_hit_number;
    DEVICE_INPUT(dev_offsets_ut_tracks_t, uint) dev_atomics_ut;
    DEVICE_INPUT(dev_offsets_ut_track_hit_number_t, uint) dev_ut_track_hit_number;
    DEVICE_INPUT(dev_ut_qop_t, float) dev_ut_qop;
    DEVICE_INPUT(dev_ut_track_velo_indices_t, uint) dev_ut_track_velo_indices;
    DEVICE_INPUT(dev_velo_kalman_beamline_states_t, char) dev_velo_kalman_beamline_states;
    DEVICE_INPUT(dev_match_upstream_muon_t, bool) dev_match_upstream_muon;
    DEVICE_INPUT(dev_event_list_mf_t, uint) dev_event_list_mf;
    DEVICE_INPUT(dev_mf_track_offsets_t, uint) dev_mf_track_offsets;
    DEVICE_OUTPUT(dev_mf_tracks_t, ParKalmanFilter::FittedTrack) dev_mf_tracks;
    HOST_INPUT(host_number_of_mf_tracks_t, uint);
    PROPERTY(block_dim_t, DeviceDimensions, "block_dim", "block dimensions", {256, 1, 1});
  };

  __global__ void package_mf_tracks(Parameters);

  template<typename T, char... S>
  struct package_mf_tracks_t : public DeviceAlgorithm, Parameters {
    constexpr static auto name = Name<S...>::s;
    decltype(global_function(package_mf_tracks)) function {package_mf_tracks};

    void set_arguments_size(
      ArgumentRefManager<T> arguments,
      const RuntimeOptions& runtime_options,
      const Constants& constants,
      const HostBuffers& host_buffers) const
    {
      set_size<dev_mf_tracks_t>(arguments, value<host_number_of_mf_tracks_t>(arguments));
    }

    void operator()(
      const ArgumentRefManager<T>& arguments,
      const RuntimeOptions& runtime_options,
      const Constants& constants,
      HostBuffers& host_buffers,
      cudaStream_t& cuda_stream,
      cudaEvent_t& cuda_generic_event) const
    {
      if (host_buffers.host_selected_events_mf[0] > 0) {
        function(dim3(host_buffers.host_selected_events_mf[0]), property<block_dim_t>(), cuda_stream)(
          Parameters {begin<dev_offsets_all_velo_tracks_t>(arguments),
              begin<dev_offsets_velo_track_hit_number_t>(arguments),
              begin<dev_offsets_ut_tracks_t>(arguments),
              begin<dev_offsets_ut_track_hit_number_t>(arguments),
              begin<dev_ut_qop_t>(arguments),
              begin<dev_ut_track_velo_indices_t>(arguments),
              begin<dev_velo_kalman_beamline_states_t>(arguments),
              begin<dev_match_upstream_muon_t>(arguments),
              begin<dev_event_list_mf_t>(arguments),
              begin<dev_mf_track_offsets_t>(arguments),
              begin<dev_mf_tracks_t>(arguments)});
      }
    }

  private:
    Property<block_dim_t> m_block_dim {this};
  };
  
} // namespace package_ut_tracks