/*****************************************************************************\
* (c) Copyright 2018-2020 CERN for the benefit of the LHCb Collaboration      *
\*****************************************************************************/
#pragma once

#include "SciFiEventModel.cuh"
#include "States.cuh"
#include "AlgorithmTypes.cuh"
#include "LookingForwardConstants.cuh"
#include "ParticleTypes.cuh"
#include "CheckerTracks.cuh"
#include "CheckerInvoker.h"
#include "TrackChecker.h"

namespace long_track_validator {
  struct Parameters {
    HOST_INPUT(host_number_of_events_t, unsigned) host_number_of_events;
    HOST_INPUT(host_number_of_reconstructed_long_tracks_t, unsigned) host_number_of_reconstructed_long_tracks;
    HOST_INPUT(host_mc_events_t, const MCEvents*) host_mc_events;
    DEVICE_INPUT(dev_velo_states_view_t, Allen::Views::Physics::KalmanStates) dev_velo_states_view;
    MASK_INPUT(dev_event_list_t) dev_event_list;
    DEVICE_INPUT(dev_multi_event_long_tracks_view_t, Allen::Views::Physics::MultiEventLongTracks)
    dev_multi_event_long_tracks_view;
    DEVICE_INPUT(dev_offsets_long_tracks_t, unsigned) dev_offsets_long_tracks;
    DEVICE_OUTPUT(dev_long_checker_tracks_t, Checker::Track) dev_long_checker_tracks;
    PROPERTY(block_dim_t, "block_dim", "block dimensions", DeviceDimensions) block_dim;
    PROPERTY(root_output_filename_t, "root_output_filename", "root output filename", std::string);
  };

  __global__ void long_track_validator(Parameters parameters);

  struct long_track_validator_t : public DeviceAlgorithm, Parameters {
    void set_arguments_size(ArgumentReferences<Parameters> arguments, const RuntimeOptions&, const Constants&) const;

    void operator()(
      const ArgumentReferences<Parameters>& arguments,
      const RuntimeOptions&,
      const Constants&,
      const Allen::Context& context) const;

  private:
    Property<block_dim_t> m_block_dim {this, {{256, 1, 1}}};
    Property<root_output_filename_t> m_root_output_filename {this, "PrCheckerPlots.root"};
  };
} // namespace long_track_validator
