/*****************************************************************************\
* (c) Copyright 2018-2020 CERN for the benefit of the LHCb Collaboration      *
\*****************************************************************************/
#pragma once

#include "DeviceAlgorithm.cuh"
#include "MuonDefinitions.cuh"
#include "States.cuh"
#include "SciFiConsolidated.cuh"

namespace is_muon {
  DEFINE_PARAMETERS(
    Parameters,
    (HOST_INPUT(host_number_of_events_t, unsigned), host_number_of_events),
    (HOST_INPUT(host_number_of_reconstructed_scifi_tracks_t, unsigned), host_number_of_reconstructed_scifi_tracks),
    (DEVICE_INPUT(dev_event_list_t, unsigned), dev_event_list),
    (DEVICE_INPUT(dev_number_of_events_t, unsigned), dev_number_of_events),
    (DEVICE_INPUT(dev_offsets_forward_tracks_t, unsigned), dev_atomics_scifi),
    (DEVICE_INPUT(dev_offsets_scifi_track_hit_number, unsigned), dev_scifi_track_hit_number),
    (DEVICE_INPUT(dev_scifi_qop_t, float), dev_scifi_qop),
    (DEVICE_INPUT(dev_scifi_states_t, MiniState), dev_scifi_states),
    (DEVICE_INPUT(dev_scifi_track_ut_indices_t, unsigned), dev_scifi_track_ut_indices),
    (DEVICE_INPUT(dev_station_ocurrences_offset_t, unsigned), dev_station_ocurrences_offset),
    (DEVICE_INPUT(dev_muon_hits_t, char), dev_muon_hits),
    (DEVICE_OUTPUT(dev_muon_track_occupancies_t, int), dev_muon_track_occupancies),
    (DEVICE_OUTPUT(dev_is_muon_t, bool), dev_is_muon),
    (PROPERTY(block_dim_x_t, "block_dim_x", "block dimension X", unsigned), block_dim_x))

  __global__ void is_muon(
    Parameters,
    const Muon::Constants::FieldOfInterest* dev_muon_foi,
    const float* dev_muon_momentum_cuts);

  struct is_muon_t : public DeviceAlgorithm, Parameters {
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
    Property<block_dim_x_t> m_block_dim_x {this, 64};
  };
} // namespace is_muon