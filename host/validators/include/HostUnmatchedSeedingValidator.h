/*****************************************************************************\
* (c) Copyright 2020 CERN for the benefit of the LHCb Collaboration           *
*                                                                             *
* This software is distributed under the terms of the Apache License          *
* version 2 (Apache-2.0), copied verbatim in the file "LICENSE".              *
*                                                                             *
* In applying this licence, CERN does not waive the privileges and immunities *
* granted to it by virtue of its status as an Intergovernmental Organization  *
* or submit itself to any jurisdiction.                                       *
\*****************************************************************************/
#pragma once

#include "BackendCommon.h"
#include "AlgorithmTypes.cuh"
#include "States.cuh"
#include "SciFiEventModel.cuh"

namespace host_unmatched_seeding_validator {
  struct Parameters {
    HOST_INPUT(host_number_of_events_t, unsigned) host_number_of_events;
    DEVICE_INPUT(dev_scifi_hits_t, char) dev_scifi_hits;
    DEVICE_INPUT(dev_scifi_seeds_t, SciFi::Seeding::Track) dev_scifi_seeds;
    DEVICE_INPUT(dev_offsets_scifi_seeds_t, unsigned) dev_atomics_scifi;
    DEVICE_INPUT(dev_offsets_scifi_seed_hit_number_t, unsigned) dev_scifi_seed_hit_number;
    DEVICE_INPUT(dev_seeding_states_t, MiniState) dev_seeding_states;

    // Matching input
    DEVICE_INPUT(dev_matched_is_scifi_track_used_t, bool) dev_matched_is_scifi_track_used;

    MASK_INPUT(dev_event_list_t) dev_event_list;
    HOST_INPUT(host_mc_events_t, const MCEvents*) host_mc_events;
  };

  struct host_unmatched_seeding_validator_t : public ValidationAlgorithm, Parameters {
    inline void set_arguments_size(ArgumentReferences<Parameters>, const RuntimeOptions&, const Constants&) const {}

    void operator()(
      const ArgumentReferences<Parameters>&,
      const RuntimeOptions&,
      const Constants&,
      const Allen::Context&) const;

  private:
    Allen::Property<std::string> m_root_output_filename {this,
                                                         "root_output_filename",
                                                         "PrCheckerPlots.root",
                                                         "root output filename"};
  };
} // namespace host_unmatched_seeding_validator
