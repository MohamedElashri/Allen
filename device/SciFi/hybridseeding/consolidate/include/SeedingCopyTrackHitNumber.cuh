/*****************************************************************************\
* (c) Copyright 2018-2020 CERN for the benefit of the LHCb Collaboration      *
*                                                                             *
* This software is distributed under the terms of the Apache License          *
* version 2 (Apache-2.0), copied verbatim in the file "LICENSE".              *
*                                                                             *
* In applying this licence, CERN does not waive the privileges and immunities *
* granted to it by virtue of its status as an Intergovernmental Organization  *
* or submit itself to any jurisdiction.                                       *
\*****************************************************************************/
#pragma once

#include "SciFiEventModel.cuh"
#include "SciFiDefinitions.cuh"
#include "AlgorithmTypes.cuh"

namespace seeding_copy_track_hit_number {
  struct Parameters {
    HOST_INPUT(host_number_of_events_t, unsigned) host_number_of_events; // input from event model
    HOST_INPUT(host_number_of_reconstructed_seeding_tracks_t, unsigned)
    host_number_of_reconstructed_seeding_tracks;                                  // input from prefix sum
    DEVICE_INPUT(dev_seeding_tracks_t, SciFi::Seeding::Track) dev_seeding_tracks; // input from seed_confirmTracks
    DEVICE_INPUT(dev_seeding_atomics_t, unsigned) dev_seeding_atomics;            // input from seed_confirmTracks

    DEVICE_OUTPUT(dev_offsets_seeding_hit_number_t, unsigned) dev_offsets_seeding_hit_number;
    HOST_OUTPUT(host_accumulated_number_of_hits_in_scifi_tracks_t, unsigned)
    host_accumulated_number_of_hits_in_scifi_tracks;
  };
  __global__ void seeding_copy_track_hit_number(Parameters);

  struct seeding_copy_track_hit_number_t : public DeviceAlgorithm, Parameters {
    void set_arguments_size(ArgumentReferences<Parameters> arguments, const RuntimeOptions&, const Constants&) const;

    void operator()(
      const ArgumentReferences<Parameters>& arguments,
      const RuntimeOptions&,
      const Constants&,
      const Allen::Context& context) const;

  private:
    Allen::Property<dim3> m_block_dim {this, "block_dim", {512, 1, 1}, "block dimensions"};
  };
} // namespace seeding_copy_track_hit_number
