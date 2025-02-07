/*****************************************************************************\
* (c) Copyright 2022 CERN for the benefit of the LHCb Collaboration          *
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
#include "States.cuh"
#include "AlgorithmTypes.cuh"
#include "ParticleTypes.cuh"
#include "CheckerTracks.cuh"
#include "CheckerInvoker.h"
#include "TrackChecker.h"

namespace downstream_validator {
  struct Parameters {

    // Basic
    MASK_INPUT(dev_event_list_t) dev_event_list;
    HOST_INPUT(host_number_of_events_t, unsigned) host_number_of_events;
    DEVICE_INPUT(dev_number_of_events_t, unsigned) dev_number_of_events;

    // MC
    HOST_INPUT(host_mc_events_t, const MCEvents*) host_mc_events;

    // Downstream output
    HOST_INPUT(host_number_of_downstream_tracks_t, unsigned) host_number_of_downstream_tracks;
    DEVICE_INPUT(dev_offsets_downstream_tracks_t, unsigned) dev_offsets_downstream_tracks;
    DEVICE_INPUT(dev_multi_event_downstream_tracks_view_t, Allen::Views::Physics::MultiEventDownstreamTracks)
    dev_multi_event_downstream_tracks_view;
    DEVICE_INPUT(dev_downstream_track_states_view_t, Allen::Views::Physics::KalmanStates)
    dev_downstream_track_states_view;

    // Output
    DEVICE_OUTPUT(dev_downstream_checker_tracks_t, Checker::Track) dev_downstream_checker_tracks;
    DEVICE_OUTPUT(dev_n_downstream_checker_tracks_t, Checker::Track) dev_n_downstream_checker_tracks;

    // Property
  };

  // __global__ Checker::Track create_track_from_seed(const SciFi::Seeding::Track seed);
  __global__ void downstream_validator(Parameters parameters);

  struct downstream_validator_t : public DeviceAlgorithm, Parameters {
    void set_arguments_size(ArgumentReferences<Parameters> arguments, const RuntimeOptions&, const Constants&) const;

    void operator()(
      const ArgumentReferences<Parameters>& arguments,
      const RuntimeOptions&,
      const Constants&,
      const Allen::Context& context) const;

  private:
    Allen::Property<dim3> m_block_dim {this, "block_dim", {1, 1, 1}, "block dimensions"};
    Allen::Property<std::string> m_root_output_filename {this,
                                                         "root_output_filename",
                                                         "PrCheckerPlots.root",
                                                         "root output filename"};
  };
} // namespace downstream_validator
