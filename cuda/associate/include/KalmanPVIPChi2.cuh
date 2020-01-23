#pragma once

// Associate Kalman-fitted long tracks to PVs using IP chi2 and store
// the calculated values.
#include "PV_Definitions.cuh"
#include "AssociateConsolidated.cuh"
#include "Common.h"
#include "DeviceAlgorithm.cuh"
#include "ParKalmanDefinitions.cuh"
#include "ParKalmanMath.cuh"
#include "States.cuh"

namespace kalman_pv_ipchi2 {
  struct Parameters {
    HOST_INPUT(host_number_of_selected_events_t, uint);
    HOST_INPUT(host_number_of_reconstructed_scifi_tracks_t, uint);
    DEVICE_OUTPUT(dev_kf_tracks_t, ParKalmanFilter::FittedTrack) dev_kf_tracks;
    DEVICE_INPUT(dev_offsets_forward_tracks_t, uint) dev_atomics_scifi;
    DEVICE_INPUT(dev_offsets_scifi_track_hit_number, uint) dev_scifi_track_hit_number;
    DEVICE_INPUT(dev_scifi_qop_t, float) dev_scifi_qop;
    DEVICE_INPUT(dev_scifi_states_t, MiniState) dev_scifi_states;
    DEVICE_INPUT(dev_scifi_track_ut_indices_t, uint) dev_scifi_track_ut_indices;
    DEVICE_INPUT(dev_multi_fit_vertices_t, PV::Vertex) dev_multi_fit_vertices;
    DEVICE_INPUT(dev_number_of_multi_fit_vertices_t, uint) dev_number_of_multi_fit_vertices;
    DEVICE_OUTPUT(dev_kalman_pv_ipchi2_t, char) dev_kalman_pv_ipchi2;
    DEVICE_INPUT(dev_is_muon_t, bool) dev_is_muon;
    PROPERTY(block_dim_t, DeviceDimensions, "block_dim", "block dimensions", {32, 1, 1});
  };

  __global__ void kalman_pv_ipchi2(Parameters);

  template<typename T, char... S>
  struct kalman_pv_ipchi2_t : public DeviceAlgorithm, Parameters {
    constexpr static auto name = Name<S...>::s;
    decltype(global_function(kalman_pv_ipchi2)) function {kalman_pv_ipchi2};

    void set_arguments_size(
      ArgumentRefManager<T> arguments,
      const RuntimeOptions& runtime_options,
      const Constants& constants,
      const HostBuffers& host_buffers) const
    {
      auto n_scifi_tracks = value<host_number_of_reconstructed_scifi_tracks_t>(arguments);
      set_size<dev_kalman_pv_ipchi2_t>(arguments, Associate::Consolidated::table_size(n_scifi_tracks));
    }

    void operator()(
      const ArgumentRefManager<T>& arguments,
      const RuntimeOptions& runtime_options,
      const Constants& constants,
      HostBuffers& host_buffers,
      cudaStream_t& cuda_stream,
      cudaEvent_t& cuda_generic_event) const
    {
      function(dim3(value<host_number_of_selected_events_t>(arguments)), property<block_dim_t>(), cuda_stream)(
        Parameters {begin<dev_kf_tracks_t>(arguments),
                    begin<dev_offsets_forward_tracks_t>(arguments),
                    begin<dev_offsets_scifi_track_hit_number>(arguments),
                    begin<dev_scifi_qop_t>(arguments),
                    begin<dev_scifi_states_t>(arguments),
                    begin<dev_scifi_track_ut_indices_t>(arguments),
                    begin<dev_multi_fit_vertices_t>(arguments),
                    begin<dev_number_of_multi_fit_vertices_t>(arguments),
                    begin<dev_kalman_pv_ipchi2_t>(arguments),
                    begin<dev_is_muon_t>(arguments)});

      cudaCheck(cudaMemcpyAsync(
        host_buffers.host_kf_tracks,
        begin<dev_kf_tracks_t>(arguments),
        size<dev_kf_tracks_t>(arguments),
        cudaMemcpyDeviceToHost,
        cuda_stream));
    }
    
  private:
    Property<block_dim_t> m_block_dim {this};
  };
} // namespace kalman_pv_ipchi2