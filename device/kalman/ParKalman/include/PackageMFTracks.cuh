#pragma once

#include "ParKalmanDefinitions.cuh"
#include "ParKalmanMath.cuh"
#include "UTConsolidated.cuh"
#include "VeloConsolidated.cuh"
#include "States.cuh"
#include "DeviceAlgorithm.cuh"

namespace package_mf_tracks {

  struct Parameters {
    HOST_INPUT(host_number_of_selected_events_t, uint);
    HOST_INPUT(host_number_of_mf_tracks_t, uint);
    HOST_OUTPUT(host_selected_events_mf_t, uint);
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
    PROPERTY(block_dim_t, "block_dim", "block dimensions", DeviceDimensions);
  };

  __global__ void package_mf_tracks(Parameters, const uint number_of_events);

  template<typename T>
  struct package_mf_tracks_t : public DeviceAlgorithm, Parameters {

    decltype(global_function(package_mf_tracks)) function {package_mf_tracks};

    void set_arguments_size(
      ArgumentRefManager<T> arguments,
      const RuntimeOptions&,
      const Constants&,
      const HostBuffers&) const
    {
      set_size<dev_mf_tracks_t>(arguments, first<host_number_of_mf_tracks_t>(arguments));
    }

    void operator()(
      const ArgumentRefManager<T>& arguments,
      const RuntimeOptions&,
      const Constants&,
      HostBuffers&,
      cudaStream_t& cuda_stream,
      cudaEvent_t&) const
    {
      initialize<dev_mf_tracks_t>(arguments, 0, cuda_stream);
      
      function(dim3(first<host_selected_events_mf_t>(arguments)), property<block_dim_t>(), cuda_stream)(
        Parameters {data<dev_offsets_all_velo_tracks_t>(arguments),
                    data<dev_offsets_velo_track_hit_number_t>(arguments),
                    data<dev_offsets_ut_tracks_t>(arguments),
                    data<dev_offsets_ut_track_hit_number_t>(arguments),
                    data<dev_ut_qop_t>(arguments),
                    data<dev_ut_track_velo_indices_t>(arguments),
                    data<dev_velo_kalman_beamline_states_t>(arguments),
                    data<dev_match_upstream_muon_t>(arguments),
                    data<dev_event_list_mf_t>(arguments),
                    data<dev_mf_track_offsets_t>(arguments),
                    data<dev_mf_tracks_t>(arguments)},
        first<host_number_of_selected_events_t>(arguments));
    }

  private:
    Property<block_dim_t> m_block_dim {this, {{256, 1, 1}}};
  };

} // namespace package_mf_tracks