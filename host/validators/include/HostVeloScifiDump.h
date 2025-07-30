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
#include "ParKalmanFittedTrack.cuh"
#include "SciFiEventModel.cuh"
#include "VeloConsolidated.cuh"
#include "UTConsolidated.cuh"
#include "SciFiConsolidated.cuh"

namespace host_veloscifi_dump {
  struct Parameters {
    HOST_INPUT(host_number_of_events_t, unsigned) host_number_of_events;
    MASK_INPUT(dev_event_list_t) dev_event_list;

    DEVICE_INPUT(dev_offsets_all_velo_tracks_t, unsigned) dev_offsets_all_velo_tracks;
    DEVICE_INPUT(dev_offsets_velo_track_hit_number_t, unsigned) dev_offsets_velo_track_hit_number;
    DEVICE_INPUT(dev_velo_track_hits_t, char) dev_velo_track_hits;
    DEVICE_INPUT(dev_velo_kalman_states_t, char) dev_velo_kalman_states;
    DEVICE_INPUT(dev_ut_velo_tracks_offsets_t, unsigned) dev_ut_velo_tracks_offsets;
    DEVICE_INPUT(dev_ut_selected_velo_tracks_t, unsigned) dev_ut_selected_velo_tracks;

    DEVICE_INPUT(dev_scifi_hits_t, char) dev_scifi_hits;
    DEVICE_INPUT(dev_scifi_seeds_t, SciFi::Seeding::Track) dev_scifi_seeds;
    DEVICE_INPUT(dev_offsets_scifi_seeds_t, unsigned) dev_atomics_scifi;
    DEVICE_INPUT(dev_offsets_scifi_seed_hit_number_t, unsigned) dev_scifi_seed_hit_number;
    DEVICE_INPUT(dev_seeding_states_t, MiniState) dev_seeding_states;

    HOST_INPUT(host_mc_events_t, const MCEvents*) host_mc_events;
  };

  struct host_veloscifi_dump_t : public ValidationAlgorithm, Parameters {
    inline void set_arguments_size(ArgumentReferences<Parameters>, const RuntimeOptions&, const Constants&) const {}

    void operator()(
      const ArgumentReferences<Parameters>&,
      const RuntimeOptions&,
      const Constants&,
      const Allen::Context&) const;

  private:
    Allen::Property<std::string> m_dump_output_filename {this,
                                                         "dump_output_filename",
                                                         "veloscifimatch.json",
                                                         "dump output filename"};
  };
} // namespace host_veloscifi_dump
