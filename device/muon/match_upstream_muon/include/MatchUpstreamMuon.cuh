/*****************************************************************************\
* (c) Copyright 2018-2020 CERN for the benefit of the LHCb Collaboration      *
\*****************************************************************************/
#pragma once

#include "DeviceAlgorithm.cuh"
#include "MuonDefinitions.cuh"
#include "FunctionsMatchUpstreamMuon.cuh"
#include "UTConsolidated.cuh"
#include "VeloConsolidated.cuh"

namespace MatchUpstreamMuon {
  DEFINE_PARAMETERS(
    Parameters,
    (HOST_INPUT(host_number_of_events_t, unsigned), host_number_of_events),
    (HOST_INPUT(host_number_of_reconstructed_ut_tracks_t, unsigned), host_number_of_reconstructed_ut_tracks),
    (HOST_INPUT(host_selected_events_mf_t, unsigned), host_selected_events_mf),
    (DEVICE_INPUT(dev_offsets_all_velo_tracks_t, unsigned), dev_atomics_velo),
    (DEVICE_INPUT(dev_offsets_velo_track_hit_number_t, unsigned), dev_velo_track_hit_number),
    (DEVICE_INPUT(dev_velo_kalman_beamline_states_t, char), dev_kalmanvelo_states),
    (DEVICE_INPUT(dev_offsets_ut_tracks_t, unsigned), dev_atomics_ut),
    (DEVICE_INPUT(dev_offsets_ut_track_hit_number_t, unsigned), dev_ut_track_hit_number),
    (DEVICE_INPUT(dev_ut_qop_t, float), dev_ut_qop),
    (DEVICE_INPUT(dev_ut_track_velo_indices_t, unsigned), dev_ut_track_velo_indices),
    (DEVICE_INPUT(dev_station_ocurrences_offset_t, unsigned), dev_station_ocurrences_offset),
    (DEVICE_INPUT(dev_muon_hits_t, char), dev_muon_hits),
    (DEVICE_INPUT(dev_event_list_mf_t, unsigned), dev_event_list_mf),
    (DEVICE_OUTPUT(dev_match_upstream_muon_t, bool), dev_muon_match),
    (PROPERTY(block_dim_t, "block_dim", "block dimensions", DeviceDimensions), block_dim))

  __global__ void match_upstream_muon(
    Parameters,
    const float* magnet_polarity,
    const MuonChambers* dev_muonmatch_search_muon_chambers,
    const SearchWindows* dev_muonmatch_search_windows,
    const unsigned number_of_events);

  struct match_upstream_muon_t : public DeviceAlgorithm, Parameters {
    void set_arguments_size(
      ArgumentReferences<Parameters> arguments,
      const RuntimeOptions&,
      const Constants&,
      const HostBuffers&) const;

    void operator()(
      const ArgumentReferences<Parameters>& arguments,
      const RuntimeOptions& runtime_options,
      const Constants& constants,
      HostBuffers& host_buffers,
      cudaStream_t& stream,
      cudaEvent_t&) const;

  private:
    Property<block_dim_t> m_block_dim {this, {{128, 1, 1}}};
  };
} // namespace MatchUpstreamMuon