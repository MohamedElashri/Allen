#pragma once

#include "ParKalmanDefinitions.cuh"
#include "ParKalmanMath.cuh"
#include "VertexDefinitions.cuh"
#include "PV_Definitions.cuh"
#include "SciFiConsolidated.cuh"
#include "UTConsolidated.cuh"
#include "VeloConsolidated.cuh"
#include "AssociateConsolidated.cuh"
#include "States.cuh"
#include "DeviceAlgorithm.cuh"

namespace FilterTracks {

  // TODO: The chi2/ndof cuts are for alignment with Moore. These cuts
  // should ultimately be defined in a selection. The fact that this
  // works out so neatly for now is coincidental.
  struct Parameters {
    HOST_INPUT(host_number_of_selected_events_t, uint);
    DEVICE_INPUT(dev_kf_tracks_t, ParKalmanFilter::FittedTrack) dev_kf_tracks;
    DEVICE_INPUT(dev_offsets_forward_tracks_t, uint) dev_atomics_scifi;
    DEVICE_INPUT(dev_offsets_scifi_track_hit_number_t, uint) dev_scifi_track_hit_number;
    DEVICE_INPUT(dev_scifi_qop_t, float) dev_scifi_qop;
    DEVICE_INPUT(dev_scifi_states_t, MiniState) dev_scifi_states;
    DEVICE_INPUT(dev_scifi_track_ut_indices_t, uint) dev_scifi_track_ut_indices;
    DEVICE_INPUT(dev_multi_fit_vertices_t, PV::Vertex) dev_multi_fit_vertices;
    DEVICE_INPUT(dev_number_of_multi_fit_vertices_t, uint) dev_number_of_multi_fit_vertices;
    DEVICE_INPUT(dev_kalman_pv_ipchi2_t, char) dev_kalman_pv_ipchi2;
    DEVICE_OUTPUT(dev_sv_atomics_t, uint) dev_sv_atomics;
    DEVICE_OUTPUT(dev_svs_trk1_idx_t, uint) dev_svs_trk1_idx;
    DEVICE_OUTPUT(dev_svs_trk2_idx_t, uint) dev_svs_trk2_idx;
    PROPERTY(track_min_pt_t, "track_min_pt", "minimum track pT", float) track_min_pt;
    PROPERTY(track_min_ipchi2_t, "track_min_ipchi2", "minimum track IP chi2", float) track_min_ipchi2;
    PROPERTY(track_muon_min_ipchi2_t, "track_muon_min_ipchi2", "minimum muon IP chi2", float) track_muon_min_ipchi2;
    PROPERTY(track_max_chi2ndof_t, "track_max_chi2ndof", "max track chi2/ndof", float) track_max_chi2ndof;
    PROPERTY(track_muon_max_chi2ndof_t, "track_muon_max_chi2ndof", "max muon chi2/ndof", float) track_muon_max_chi2ndof;
    PROPERTY(max_assoc_ipchi2_t, "max_assoc_ipchi2", "maximum IP chi2 to associate to PV", float)
    max_assoc_ipchi2;
    PROPERTY(block_dim_t, "block_dim", "block dimensions", DeviceDimensions);
  };

  __global__ void filter_tracks(Parameters);

  template<typename T>
  struct filter_tracks_t : public DeviceAlgorithm, Parameters {

    decltype(global_function(filter_tracks)) function {filter_tracks};

    void set_arguments_size(
      ArgumentRefManager<T> arguments,
      const RuntimeOptions&,
      const Constants&,
      const HostBuffers&) const
    {
      set_size<dev_sv_atomics_t>(
        arguments, first<host_number_of_selected_events_t>(arguments));
      set_size<dev_svs_trk1_idx_t>(
        arguments, 10 * VertexFit::max_svs * first<host_number_of_selected_events_t>(arguments));
      set_size<dev_svs_trk2_idx_t>(
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
      initialize<dev_sv_atomics_t>(arguments, 0, cuda_stream);

      function(
        dim3(first<host_number_of_selected_events_t>(arguments)),
        property<block_dim_t>(),
        cuda_stream)(
        Parameters {data<dev_kf_tracks_t>(arguments),
            data<dev_offsets_forward_tracks_t>(arguments),
            data<dev_offsets_scifi_track_hit_number_t>(arguments),
            data<dev_scifi_qop_t>(arguments),
            data<dev_scifi_states_t>(arguments),
            data<dev_scifi_track_ut_indices_t>(arguments),
            data<dev_multi_fit_vertices_t>(arguments),
            data<dev_number_of_multi_fit_vertices_t>(arguments),
            data<dev_kalman_pv_ipchi2_t>(arguments),
            data<dev_sv_atomics_t>(arguments),
            data<dev_svs_trk1_idx_t>(arguments),
            data<dev_svs_trk2_idx_t>(arguments),
            property<track_min_pt_t>(),
            property<track_min_ipchi2_t>(),
            property<track_muon_min_ipchi2_t>(),
            property<track_max_chi2ndof_t>(),
            property<track_muon_max_chi2ndof_t>(),
            property<max_assoc_ipchi2_t>()});
    }

  private:
    Property<track_min_pt_t> m_minpt {this, 200.0f};
    Property<track_min_ipchi2_t> m_minipchi2 {this, 9.0f};
    Property<track_muon_min_ipchi2_t> m_minmuipchi2 {this, 4.0f};
    Property<track_max_chi2ndof_t> m_maxchi2ndof {this, 2.5f};
    Property<track_muon_max_chi2ndof_t> m_muonmaxchi2ndof {this, 100.f};
    Property<max_assoc_ipchi2_t> m_maxassocipchi2 {this, 16.0f};
    Property<block_dim_t> m_block_dim {this, {{16, 16, 1}}};
  };               
    
} // namespace FilterTracks
