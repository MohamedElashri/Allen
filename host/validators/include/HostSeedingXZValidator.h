/*****************************************************************************\
* (c) Copyright 2020 CERN for the benefit of the LHCb Collaboration           *
\*****************************************************************************/
#pragma once

#include "BackendCommon.h"
#include "AlgorithmTypes.cuh"
#include "States.cuh"
#include "SciFiEventModel.cuh"

namespace host_seeding_XZ_validator {
  struct Parameters {
    HOST_INPUT(host_number_of_events_t, unsigned) host_number_of_events;
    DEVICE_INPUT(dev_scifi_hits_t, char) dev_scifi_hits;
    DEVICE_INPUT(dev_scifi_seedsXZ_t, SciFi::Seeding::TrackXZ) dev_scifi_seedsXZ;
    DEVICE_INPUT(dev_offsets_scifi_seedsXZ_t, unsigned) dev_atomics_scifi; // FIXME
    DEVICE_INPUT(dev_offsets_scifi_seedXZ_hit_number_t, unsigned) dev_scifi_seedXZ_hit_number;
    MASK_INPUT(dev_event_list_t) dev_event_list;
    HOST_INPUT(host_mc_events_t, const MCEvents*) host_mc_events;
    PROPERTY(root_output_filename_t, "root_output_filename", "root output filename", std::string);
  };

  struct host_seeding_XZ_validator_t : public ValidationAlgorithm, Parameters {
    inline void set_arguments_size(ArgumentReferences<Parameters>, const RuntimeOptions&, const Constants&) const {}

    void operator()(
      const ArgumentReferences<Parameters>&,
      const RuntimeOptions&,
      const Constants&,
      const Allen::Context&) const;

  private:
    Property<root_output_filename_t> m_root_output_filename {this, "PrCheckerPlots.root"};
  };
} // namespace host_seeding_XZ_validator
