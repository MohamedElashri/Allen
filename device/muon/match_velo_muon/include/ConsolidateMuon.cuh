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
#include "UTConsolidated.cuh"
#include "VeloConsolidated.cuh"
#include "States.cuh"

namespace consolidate_muon {
  struct Parameters {
    MASK_INPUT(dev_event_list_t) dev_event_list;

    HOST_INPUT(host_number_of_events_t, unsigned) host_number_of_events;
    HOST_INPUT(host_muon_total_number_of_tracks_t, unsigned) host_muon_total_number_of_tracks;

    DEVICE_INPUT(dev_number_of_events_t, unsigned) dev_number_of_events;
    DEVICE_INPUT(dev_muon_tracks_input_t, MuonTrack) dev_muon_tracks_input;
    DEVICE_INPUT(dev_muon_tracks_offsets_t, unsigned) dev_muon_tracks_offsets;
    DEVICE_OUTPUT(dev_muon_tracks_output_t, MuonTrack) dev_muon_tracks_output;
  };

  __global__ void consolidate_muon(Parameters);

  struct consolidate_muon_t : public DeviceAlgorithm, Parameters {
    void set_arguments_size(ArgumentReferences<Parameters> arguments, const RuntimeOptions&, const Constants&) const;

    void operator()(
      const ArgumentReferences<Parameters>& arguments,
      const RuntimeOptions& runtime_options,
      const Constants& constants,
      const Allen::Context& context) const;

  private:
    Allen::Property<unsigned> m_block_dim_x {this, "block_dim_x", 64, "block dimension X"};
  };

} // namespace consolidate_muon
