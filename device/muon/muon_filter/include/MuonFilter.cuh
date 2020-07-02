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
  DEFINE_PARAMETERS(
    Parameters,
    (HOST_INPUT(host_number_of_selected_events_t, unsigned), host_number_of_selected_events),
    (HOST_OUTPUT(host_selected_events_mf_t, unsigned), host_selected_events_mf),
    (DEVICE_INPUT(dev_offsets_all_velo_tracks_t, unsigned), dev_atomics_velo),
    (DEVICE_INPUT(dev_offsets_velo_track_hit_number_t, unsigned), dev_velo_track_hit_number),
    (DEVICE_INPUT(dev_velo_kalman_beamline_states_t, char), dev_kalmanvelo_states),
    (DEVICE_INPUT(dev_velo_track_hits_t, char), dev_velo_track_hits),
    (DEVICE_INPUT(dev_offsets_ut_tracks_t, unsigned), dev_atomics_ut),
    (DEVICE_INPUT(dev_offsets_ut_track_hit_number_t, unsigned), dev_ut_track_hit_number),
    (DEVICE_INPUT(dev_ut_qop_t, float), dev_ut_qop),
    (DEVICE_INPUT(dev_ut_track_velo_indices_t, unsigned), dev_ut_track_velo_indices),
    (DEVICE_INPUT(dev_offsets_forward_tracks_t, unsigned), dev_atomics_scifi),
    (DEVICE_INPUT(dev_offsets_scifi_track_hit_number, unsigned), dev_scifi_track_hit_number),
    (DEVICE_INPUT(dev_scifi_qop_t, float), dev_scifi_qop),
    (DEVICE_INPUT(dev_scifi_states_t, MiniState), dev_scifi_states),
    (DEVICE_INPUT(dev_scifi_track_ut_indices_t, unsigned), dev_scifi_track_ut_indices),
    (DEVICE_INPUT(dev_is_muon_t, bool), dev_is_muon),
    (DEVICE_INPUT(dev_kalman_pv_ipchi2_t, char), dev_kalman_pv_ipchi2),
    (DEVICE_OUTPUT(dev_mf_decisions_t, unsigned), dev_mf_decisions),
    (DEVICE_OUTPUT(dev_event_list_mf_t, unsigned), dev_event_list_mf),
    (DEVICE_OUTPUT(dev_selected_events_mf_t, unsigned), dev_selected_events_mf),
    (DEVICE_OUTPUT(dev_mf_track_atomics_t, unsigned), dev_mf_track_atomics),
    (PROPERTY(mf_min_pt_t, "mf_min_pt", "minimum track pT", float), mf_min_pt),
    (PROPERTY(mf_min_ipchi2_t, "mf_min_ipchi2", "minimum track IP chi2", float), mf_min_ipchi2),
    (PROPERTY(block_dim_t, "block_dim", "block dimensions", DeviceDimensions), block_dim))

  __global__ void muon_filter(Parameters);

  struct muon_filter_t : public DeviceAlgorithm, Parameters {
    void set_arguments_size(
      ArgumentReferences<Parameters> arguments,
      const RuntimeOptions&,
      const Constants&,
      const HostBuffers&) const;

    void operator()(
      const ArgumentReferences<Parameters>& arguments,
      const RuntimeOptions& runtime_options,
      const Constants&,
      HostBuffers& host_buffers,
      cudaStream_t& cuda_stream,
      cudaEvent_t&) const;

  private:
    Property<mf_min_pt_t> m_minpt {this, 800.f};
    Property<mf_min_ipchi2_t> m_minipchi2 {this, 16.f};
    Property<block_dim_t> m_block_dim {this, {{256, 1, 1}}};
  };
} // namespace MuonFilter