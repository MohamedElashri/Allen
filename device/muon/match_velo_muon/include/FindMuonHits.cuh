/*****************************************************************************\
* (c) Copyright 2022 CERN for the benefit of the LHCb Collaboration      *
\*****************************************************************************/
#pragma once

#include "AlgorithmTypes.cuh"
#include "MuonDefinitions.cuh"
#include "UTConsolidated.cuh"
#include "VeloConsolidated.cuh"
#include "States.cuh"
#include "ROOTService.h"

namespace find_muon_hits {
  struct Parameters {
    MASK_INPUT(dev_event_list_t) dev_event_list;

    HOST_INPUT(host_number_of_events_t, unsigned) host_number_of_events;

    DEVICE_INPUT(dev_muon_hits_t, char) dev_muon_hits;
    DEVICE_INPUT(dev_number_of_events_t, unsigned) dev_number_of_events;
    DEVICE_INPUT(dev_station_ocurrences_offset_t, unsigned) dev_station_ocurrences_offset;
    DEVICE_OUTPUT(dev_muon_tracks_t, MuonTrack) dev_muon_tracks;
    DEVICE_OUTPUT(dev_muon_number_of_tracks_t, unsigned) dev_muon_number_of_tracks;

    PROPERTY(block_dim_x_t, "block_dim_x", "block dimension X", unsigned) block_dim_x;
    PROPERTY(enable_monitoring_t, "enable_monitoring", "Enable monitoring boolean", bool) enable_monitoring;
    PROPERTY(required_number_of_hits_t, "required_number_of_hits", "Minimum number of hits to accept a muon stub", int)
    required_number_of_hits;
  };

  __global__ void find_muon_hits(Parameters, const Muon::Constants::MatchWindows* dev_match_windows);

  struct find_muon_hits_t : public DeviceAlgorithm, Parameters {
    void set_arguments_size(
      ArgumentReferences<Parameters> arguments,
      const RuntimeOptions&,
      const Constants&) const;

    void operator()(
      const ArgumentReferences<Parameters>& arguments,
      const RuntimeOptions& runtime_options,
      const Constants& constants,
      const Allen::Context& context) const;

    void output_monitor(
      const ArgumentReferences<Parameters>& arguments,
      const RuntimeOptions& runtime_options,
      const Allen::Context& context) const;

  private:
    Property<block_dim_x_t> m_block_dim_x {this, 64};
    Property<enable_monitoring_t> m_enable_monitoring {this, false};
    Property<required_number_of_hits_t> m_required_number_of_hits {this, 4};
  };

} // namespace find_muon_hits
