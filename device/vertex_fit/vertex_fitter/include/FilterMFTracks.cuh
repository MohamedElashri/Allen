#pragma once

#include "ParKalmanDefinitions.cuh"
#include "ParKalmanMath.cuh"
#include "VertexDefinitions.cuh"
#include "SciFiConsolidated.cuh"
#include "UTConsolidated.cuh"
#include "States.cuh"
#include "DeviceAlgorithm.cuh"

namespace FilterMFTracks {

  struct Parameters {
    HOST_INPUT(host_number_of_selected_events_t, uint);
    HOST_INPUT(host_selected_events_mf_t, uint);
    DEVICE_INPUT(dev_kf_tracks_t, ParKalmanFilter::FittedTrack) dev_kf_tracks;
    DEVICE_INPUT(dev_mf_tracks_t, ParKalmanFilter::FittedTrack) dev_mf_tracks;
    DEVICE_INPUT(dev_offsets_forward_tracks_t, uint) dev_atomics_scifi;
    DEVICE_INPUT(dev_offsets_scifi_track_hit_number, uint) dev_scifi_track_hit_number;
    DEVICE_INPUT(dev_scifi_qop_t, float) dev_scifi_qop;
    DEVICE_INPUT(dev_scifi_states_t, MiniState) dev_scifi_states;
    DEVICE_INPUT(dev_scifi_track_ut_indices_t, uint) dev_scifi_track_ut_indices;
    DEVICE_INPUT(dev_mf_track_offsets_t, uint) dev_mf_track_offsets;
    DEVICE_INPUT(dev_event_list_mf_t, uint) dev_event_list_mf;
    DEVICE_OUTPUT(dev_mf_sv_atomics_t, uint) dev_mf_sv_atomics;
    DEVICE_OUTPUT(dev_svs_kf_idx_t, uint) dev_svs_kf_idx;
    DEVICE_OUTPUT(dev_svs_mf_idx_t, uint) dev_svs_mf_idx;
    PROPERTY(kf_track_min_pt_t, "kf_track_min_pt", "minimum track pT", float) kf_track_min_pt;
    PROPERTY(kf_track_min_ipchi2_t, "kf_track_min_ipchi2", "minimum track IP chi2", float) kf_track_min_ipchi2;
    PROPERTY(mf_track_min_pt_t, "mf_track_min_pt", "minimum velo-UT-muon track pt", float) mf_track_min_pt;
    PROPERTY(block_dim_t, "block_dim", "block dimensions", DeviceDimensions);
  };

  __global__ void filter_mf_tracks(Parameters, const uint number_of_events);

  template<typename T>
  struct filter_mf_tracks_t : public DeviceAlgorithm, Parameters {

    decltype(global_function(filter_mf_tracks)) function {filter_mf_tracks};

    void set_arguments_size(
      ArgumentRefManager<T> arguments,
      const RuntimeOptions&,
      const Constants&,
      const HostBuffers&) const
    {
      set_size<dev_mf_sv_atomics_t>(arguments, first<host_number_of_selected_events_t>(arguments));
      set_size<dev_svs_kf_idx_t>(
        arguments, 10 * VertexFit::max_svs * first<host_number_of_selected_events_t>(arguments));
      set_size<dev_svs_mf_idx_t>(
        arguments, 10 * VertexFit::max_svs * first<host_number_of_selected_events_t>(arguments));
    }

    void operator()(
      const ArgumentRefManager<T>& arguments,
      const RuntimeOptions&,
      const Constants&,
      HostBuffers&,
      cudaStream_t& cuda_stream,
      cudaEvent_t&) const
    {
      initialize<dev_mf_sv_atomics_t>(arguments, 0, cuda_stream);
      initialize<dev_svs_kf_idx_t>(arguments, 0, cuda_stream);
      initialize<dev_svs_mf_idx_t>(arguments, 0, cuda_stream);

      function(dim3(first<host_selected_events_mf_t>(arguments)), property<block_dim_t>(), cuda_stream)(
        Parameters {data<dev_kf_tracks_t>(arguments),
                    data<dev_mf_tracks_t>(arguments),
                    data<dev_offsets_forward_tracks_t>(arguments),
                    data<dev_offsets_scifi_track_hit_number>(arguments),
                    data<dev_scifi_qop_t>(arguments),
                    data<dev_scifi_states_t>(arguments),
                    data<dev_scifi_track_ut_indices_t>(arguments),
                    data<dev_mf_track_offsets_t>(arguments),
                    data<dev_event_list_mf_t>(arguments),
                    data<dev_mf_sv_atomics_t>(arguments),
                    data<dev_svs_kf_idx_t>(arguments),
                    data<dev_svs_mf_idx_t>(arguments)},
        first<host_number_of_selected_events_t>(arguments));
    }

  private:
    Property<kf_track_min_pt_t> m_kfminpt {this, 800.f};
    Property<kf_track_min_ipchi2_t> m_kfminipchi2 {this, 16.f};
    Property<mf_track_min_pt_t> m_mfminpt {this, 200.f};
    Property<block_dim_t> m_block_dim {this, {{16, 16, 1}}};
  };

} // namespace FilterMFTracks