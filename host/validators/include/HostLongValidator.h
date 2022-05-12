/*****************************************************************************\
* (c) Copyright 2020 CERN for the benefit of the LHCb Collaboration           *
\*****************************************************************************/
#pragma once

#include "BackendCommon.h"
#include "AlgorithmTypes.cuh"
#include "States.cuh"
#include "ParticleTypes.cuh"

namespace host_long_validator {
  struct Parameters {
    HOST_INPUT(host_number_of_events_t, unsigned) host_number_of_events;
    MASK_INPUT(dev_event_list_t) dev_event_list;
    DEVICE_INPUT(dev_velo_states_view_t, Allen::Views::Velo::Consolidated::States) dev_velo_states_view;
    DEVICE_INPUT(dev_multi_event_long_tracks_view_t, Allen::Views::Physics::MultiEventLongTracks) dev_long_tracks_view;
    HOST_INPUT(host_mc_events_t, const MCEvents*) host_mc_events;
    PROPERTY(root_output_filename_t, "root_output_filename", "root output filename", std::string);
  };

  struct host_long_validator_t : public ValidationAlgorithm, Parameters {
    inline void set_arguments_size(
      ArgumentReferences<Parameters>,
      const RuntimeOptions&,
      const Constants&,
      const HostBuffers&) const
    {}

    void operator()(
      const ArgumentReferences<Parameters>&,
      const RuntimeOptions&,
      const Constants&,
      HostBuffers&,
      const Allen::Context&) const;

  private:
    Property<root_output_filename_t> m_root_output_filename {this, "PrCheckerPlots.root"};
  };
} // namespace host_long_validator