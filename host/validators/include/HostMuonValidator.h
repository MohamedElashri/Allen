/*****************************************************************************\
* (c) Copyright 2020 CERN for the benefit of the LHCb Collaboration           *
\*****************************************************************************/
#pragma once

#include "BackendCommon.h"
#include "AlgorithmTypes.cuh"
#include "States.cuh"
#include "ParticleTypes.cuh"

namespace host_muon_validator {
  struct Parameters {
    HOST_INPUT(host_number_of_events_t, unsigned) host_number_of_events;
    MASK_INPUT(dev_event_list_t) dev_event_list;
    HOST_INPUT(host_mc_events_t, const MCEvents*) host_mc_events;
    DEVICE_INPUT(dev_is_muon_t, bool) dev_is_muon;
    DEVICE_INPUT(dev_long_checker_tracks_t, SciFi::LongCheckerTrack) dev_long_checker_tracks;
    DEVICE_INPUT(dev_offsets_long_tracks_t, unsigned) dev_offsets_long_tracks;
    PROPERTY(root_output_filename_t, "root_output_filename", "root output filename", std::string);
  };

  struct host_muon_validator_t : public ValidationAlgorithm, Parameters {
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
} // namespace host_muon_validator
