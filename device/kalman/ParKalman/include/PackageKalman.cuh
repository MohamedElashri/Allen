#pragma once

#include "KalmanParametrizations.cuh"
#include "ParKalmanDefinitions.cuh"
#include "ParKalmanMath.cuh"
#include "ParKalmanMethods.cuh"
#include "SciFiConsolidated.cuh"
#include "UTConsolidated.cuh"
#include "VeloConsolidated.cuh"
#include "States.cuh"
#include "SciFiDefinitions.cuh"
#include "DeviceAlgorithm.cuh"

namespace package_kalman_tracks {
  struct Parameters {
    HOST_INPUT(host_number_of_selected_events_t, uint);
    HOST_INPUT(host_number_of_reconstructed_scifi_tracks_t, uint);
    DEVICE_INPUT(dev_atomics_velo_t, uint) dev_atomics_velo;
    DEVICE_INPUT(dev_velo_track_hit_number_t, uint) dev_velo_track_hit_number;
    DEVICE_INPUT(dev_atomics_ut_t, uint) dev_atomics_ut;
    DEVICE_INPUT(dev_ut_track_hit_number_t, uint) dev_ut_track_hit_number;
    DEVICE_INPUT(dev_ut_qop_t, float) dev_ut_qop;
    DEVICE_INPUT(dev_ut_track_velo_indices_t, uint) dev_ut_track_velo_indices;
    DEVICE_INPUT(dev_atomics_scifi_t, uint) dev_atomics_scifi;
    DEVICE_INPUT(dev_scifi_track_hit_number_t, uint) dev_scifi_track_hit_number;
    DEVICE_INPUT(dev_scifi_qop_t, float) dev_scifi_qop;
    DEVICE_INPUT(dev_scifi_states_t, MiniState) dev_scifi_states;
    DEVICE_INPUT(dev_scifi_track_ut_indices_t, uint) dev_scifi_track_ut_indices;
    DEVICE_INPUT(dev_velo_kalman_beamline_states_t, char) dev_velo_kalman_beamline_states;
    DEVICE_INPUT(dev_is_muon_t, bool) dev_is_muon;
    DEVICE_OUTPUT(dev_kf_tracks_t, ParKalmanFilter::FittedTrack) dev_kf_tracks;
    PROPERTY(block_dim_t, "block_dim", "block dimensions", DeviceDimensions);
  };

  __global__ void package_kalman_tracks(Parameters);

  template<typename T>
  struct package_kalman_tracks_t : public DeviceAlgorithm, Parameters {

    decltype(global_function(package_kalman_tracks)) function {package_kalman_tracks};

    void set_arguments_size(
      ArgumentRefManager<T> arguments,
      const RuntimeOptions&,
      const Constants&,
      const HostBuffers&) const
    {
      set_size<dev_kf_tracks_t>(arguments, first<host_number_of_reconstructed_scifi_tracks_t>(arguments));
    }

    void operator()(
      const ArgumentRefManager<T>& arguments,
      const RuntimeOptions&,
      const Constants&,
      HostBuffers&,
      cudaStream_t& cuda_stream,
      cudaEvent_t&) const
    {
      function(dim3(first<host_number_of_selected_events_t>(arguments)), property<block_dim_t>(), cuda_stream)(
        Parameters {data<dev_atomics_velo_t>(arguments),
                    data<dev_velo_track_hit_number_t>(arguments),
                    data<dev_atomics_ut_t>(arguments),
                    data<dev_ut_track_hit_number_t>(arguments),
                    data<dev_ut_qop_t>(arguments),
                    data<dev_ut_track_velo_indices_t>(arguments),
                    data<dev_atomics_scifi_t>(arguments),
                    data<dev_scifi_track_hit_number_t>(arguments),
                    data<dev_scifi_qop_t>(arguments),
                    data<dev_scifi_states_t>(arguments),
                    data<dev_scifi_track_ut_indices_t>(arguments),
                    data<dev_velo_kalman_beamline_states_t>(arguments),
                    data<dev_is_muon_t>(arguments),
                    data<dev_kf_tracks_t>(arguments)});
    }

  private:
    Property<block_dim_t> m_block_dim {this, {{256, 1, 1}}};
  };
} // namespace package_kalman_tracks