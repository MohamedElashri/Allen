#pragma once

#include "DeviceAlgorithm.cuh"
#include "MuonDefinitions.cuh"
#include "Common.h"
#include "SciFiRaw.cuh"
#include "UTRaw.cuh"
#include "States.cuh"
#include "SciFiConsolidated.cuh"
#include "AssociateConsolidated.cuh"
#include "AssociateConstants.cuh"
#include "VeloConsolidated.cuh"
#include "UTConsolidated.cuh"
#include "SystemOfUnits.h"

namespace MuonFilter {
  struct Parameters {
    HOST_INPUT(host_number_of_selected_events_t, uint);
    HOST_OUTPUT(host_selected_events_mf_t, uint);
    DEVICE_INPUT(dev_offsets_all_velo_tracks_t, uint) dev_atomics_velo;
    DEVICE_INPUT(dev_offsets_velo_track_hit_number_t, uint) dev_velo_track_hit_number;
    DEVICE_INPUT(dev_velo_kalman_beamline_states_t, char) dev_kalmanvelo_states;
    DEVICE_INPUT(dev_velo_track_hits_t, char) dev_velo_track_hits;
    DEVICE_INPUT(dev_offsets_ut_tracks_t, uint) dev_atomics_ut;
    DEVICE_INPUT(dev_offsets_ut_track_hit_number_t, uint) dev_ut_track_hit_number;
    DEVICE_INPUT(dev_ut_qop_t, float) dev_ut_qop;
    DEVICE_INPUT(dev_ut_track_velo_indices_t, uint) dev_ut_track_velo_indices;
    DEVICE_INPUT(dev_offsets_forward_tracks_t, uint) dev_atomics_scifi;
    DEVICE_INPUT(dev_offsets_scifi_track_hit_number, uint) dev_scifi_track_hit_number;
    DEVICE_INPUT(dev_scifi_qop_t, float) dev_scifi_qop;
    DEVICE_INPUT(dev_scifi_states_t, MiniState) dev_scifi_states;
    DEVICE_INPUT(dev_scifi_track_ut_indices_t, uint) dev_scifi_track_ut_indices;
    DEVICE_INPUT(dev_is_muon_t, bool) dev_is_muon;
    DEVICE_INPUT(dev_kalman_pv_ipchi2_t, char) dev_kalman_pv_ipchi2;
    DEVICE_OUTPUT(dev_mf_decisions_t, uint) dev_mf_decisions;
    DEVICE_OUTPUT(dev_event_list_mf_t, uint) dev_event_list_mf;
    DEVICE_OUTPUT(dev_selected_events_mf_t, uint) dev_selected_events_mf;
    DEVICE_OUTPUT(dev_mf_track_atomics_t, uint) dev_mf_track_atomics;
    PROPERTY(mf_min_pt_t, "mf_min_pt", "minimum track pT", float) mf_min_pt;
    PROPERTY(mf_min_ipchi2_t, "mf_min_ipchi2", "minimum track IP chi2", float) mf_min_ipchi2;
    PROPERTY(block_dim_t, "block_dim", "block dimensions", DeviceDimensions);
  };

  __global__ void muon_filter(Parameters);

  template<typename T>
  struct muon_filter_t : public DeviceAlgorithm, Parameters {

    decltype(global_function(muon_filter)) function {muon_filter};

    void set_arguments_size(
      ArgumentRefManager<T> arguments,
      const RuntimeOptions&,
      const Constants&,
      const HostBuffers&) const
    {
      set_size<dev_event_list_mf_t>(arguments, first<host_number_of_selected_events_t>(arguments));
      set_size<dev_selected_events_mf_t>(arguments, 1);
      set_size<host_selected_events_mf_t>(arguments, 1);
      set_size<dev_mf_decisions_t>(arguments, first<host_number_of_selected_events_t>(arguments));
      set_size<dev_mf_track_atomics_t>(arguments, first<host_number_of_selected_events_t>(arguments));
    }

    void operator()(
      const ArgumentRefManager<T>& arguments,
      const RuntimeOptions& runtime_options,
      const Constants&,
      HostBuffers& host_buffers,
      cudaStream_t& cuda_stream,
      cudaEvent_t&) const
    {
      initialize<dev_event_list_mf_t>(arguments, 0, cuda_stream);
      initialize<dev_selected_events_mf_t>(arguments, 0, cuda_stream);
      initialize<dev_mf_decisions_t>(arguments, 0, cuda_stream);
      initialize<dev_mf_track_atomics_t>(arguments, 0, cuda_stream);

      function(dim3(first<host_number_of_selected_events_t>(arguments)), property<block_dim_t>(), cuda_stream)(
        Parameters {data<dev_offsets_all_velo_tracks_t>(arguments),
                    data<dev_offsets_velo_track_hit_number_t>(arguments),
                    data<dev_velo_kalman_beamline_states_t>(arguments),
                    data<dev_velo_track_hits_t>(arguments),
                    data<dev_offsets_ut_tracks_t>(arguments),
                    data<dev_offsets_ut_track_hit_number_t>(arguments),
                    data<dev_ut_qop_t>(arguments),
                    data<dev_ut_track_velo_indices_t>(arguments),
                    data<dev_offsets_forward_tracks_t>(arguments),
                    data<dev_offsets_scifi_track_hit_number>(arguments),
                    data<dev_scifi_qop_t>(arguments),
                    data<dev_scifi_states_t>(arguments),
                    data<dev_scifi_track_ut_indices_t>(arguments),
                    data<dev_is_muon_t>(arguments),
                    data<dev_kalman_pv_ipchi2_t>(arguments),
                    data<dev_mf_decisions_t>(arguments),
                    data<dev_event_list_mf_t>(arguments),
                    data<dev_selected_events_mf_t>(arguments),
                    data<dev_mf_track_atomics_t>(arguments),
                    property<mf_min_pt_t>(),
                    property<mf_min_ipchi2_t>()});

      // copy<host_selected_events_mf_t, dev_selected_events_mf_t>(arguments, cuda_stream);
      cudaCheck(cudaMemcpyAsync(
        data<host_selected_events_mf_t>(arguments),
        data<dev_selected_events_mf_t>(arguments),
        size<dev_selected_events_mf_t>(arguments),
        cudaMemcpyDeviceToHost,
        cuda_stream));

      cudaCheck(cudaMemcpyAsync(
        host_buffers.host_selected_events_mf,
        data<dev_selected_events_mf_t>(arguments),
        size<dev_selected_events_mf_t>(arguments),
        cudaMemcpyDeviceToHost,
        cuda_stream));

      if (runtime_options.do_check) {
        cudaCheck(cudaMemcpyAsync(
          host_buffers.host_event_list_mf,
          data<dev_event_list_mf_t>(arguments),
          size<dev_event_list_mf_t>(arguments),
          cudaMemcpyDeviceToHost,
          cuda_stream));
      }
    }

  private:
    Property<mf_min_pt_t> m_minpt {this, 800.f};
    Property<mf_min_ipchi2_t> m_minipchi2 {this, 16.f};
    Property<block_dim_t> m_block_dim {this, {{256, 1, 1}}};
  };
} // namespace MuonFilter