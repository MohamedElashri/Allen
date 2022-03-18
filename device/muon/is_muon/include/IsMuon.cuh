/*****************************************************************************\
* (c) Copyright 2018-2020 CERN for the benefit of the LHCb Collaboration      *
\*****************************************************************************/
#pragma once

#include "AlgorithmTypes.cuh"
#include "MuonDefinitions.cuh"
#include "States.cuh"
#include "SciFiConsolidated.cuh"

namespace is_muon {
  struct Parameters {
    HOST_INPUT(host_number_of_events_t, unsigned) host_number_of_events;
    HOST_INPUT(host_number_of_reconstructed_scifi_tracks_t, unsigned) host_number_of_reconstructed_scifi_tracks;
    MASK_INPUT(dev_event_list_t) dev_event_list;
    DEVICE_INPUT(dev_number_of_events_t, unsigned) dev_number_of_events;
    DEVICE_INPUT(dev_scifi_tracks_view_t, Allen::Views::SciFi::Consolidated::Tracks) dev_scifi_tracks_view;
    DEVICE_INPUT(dev_scifi_states_t, MiniState) dev_scifi_states;
    DEVICE_INPUT(dev_station_ocurrences_offset_t, unsigned) dev_station_ocurrences_offset;
    DEVICE_INPUT(dev_muon_hits_t, char) dev_muon_hits;
    DEVICE_OUTPUT(dev_is_muon_t, uint8_t) dev_is_muon;
    PROPERTY(block_dim_x_t, "block_dim_x", "block dimension X", unsigned) block_dim_x;
  };

  __global__ void
  is_muon(Parameters, const Muon::Constants::FieldOfInterest* dev_muon_foi, const float* dev_muon_momentum_cuts);

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
      const Allen::Context& context) const;

  private:
    Property<block_dim_x_t> m_block_dim_x {this, 128};
  };
} // namespace is_muon