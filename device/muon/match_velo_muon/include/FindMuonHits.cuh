/*****************************************************************************\
* (c) Copyright 2022 CERN for the benefit of the LHCb Collaboration      *
*                                                                             *
* This software is distributed under the terms of the Apache License          *
* version 2 (Apache-2.0), copied verbatim in the file "LICENSE".              *
*                                                                             *
* In applying this licence, CERN does not waive the privileges and immunities *
* granted to it by virtue of its status as an Intergovernmental Organization  *
* or submit itself to any jurisdiction.                                       *
\*****************************************************************************/
#pragma once

#include "AlgorithmTypes.cuh"
#include "MuonEventModel.cuh"
#include "MuonSegmentFit.cuh"
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
    DEVICE_OUTPUT(dev_muon_tracks_buffer_t, MuonTrack) dev_muon_tracks_buffer;
    DEVICE_OUTPUT(dev_muon_tracks_offsets_t, unsigned) dev_muon_tracks_offsets;
    HOST_OUTPUT(host_muon_total_number_of_tracks_t, unsigned) host_muon_total_number_of_tracks;
  };

  __global__ void
  find_muon_hits(Parameters, const Muon::Constants::MatchWindows* dev_match_windows, const int required_number_of_hits);

  struct find_muon_hits_t : public DeviceAlgorithm, Parameters {
    void set_arguments_size(ArgumentReferences<Parameters> arguments, const RuntimeOptions&, const Constants&) const;

    void operator()(
      const ArgumentReferences<Parameters>& arguments,
      const RuntimeOptions& runtime_options,
      const Constants& constants,
      const Allen::Context& context) const;

    void output_tuples(
      const ArgumentReferences<Parameters>& arguments,
      const RuntimeOptions& runtime_options,
      const Allen::Context& context) const;

  private:
    Allen::Property<unsigned> m_block_dim_x {this, "block_dim_x", 64, "block dimension X"};
    Allen::Property<bool> m_enable_tupling {this, "enable_tupling", false, "Enable tupling boolean"};
    Allen::Property<int> m_required_number_of_hits {this,
                                                    "required_number_of_hits",
                                                    4,
                                                    "Minimum number of hits to accept a muon stub"};
  };

} // namespace find_muon_hits
