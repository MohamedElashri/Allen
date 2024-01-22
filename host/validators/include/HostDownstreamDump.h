/*****************************************************************************\
* (c) Copyright 2020 CERN for the benefit of the LHCb Collaboration           *
\*****************************************************************************/
#pragma once

// #include "SciFiDefinitions.cuh"
// #include "SciFiConsolidated.cuh"
// #include "SciFiEventModel.cuh"
// #include "AlgorithmTypes.cuh"

#include "BackendCommon.h"
#include "AlgorithmTypes.cuh"
#include "States.cuh"
#include "ParKalmanFittedTrack.cuh"
#include "SciFiEventModel.cuh"
#include "VeloConsolidated.cuh"
#include "UTConsolidated.cuh"
#include "SciFiConsolidated.cuh"
namespace host_downstream_dump {
  struct Parameters {
    // Basic
    HOST_INPUT(host_number_of_events_t, unsigned) host_number_of_events;
    MASK_INPUT(dev_event_list_t) dev_event_list;

    // UT hits
    DEVICE_INPUT(dev_ut_hits_t, char) dev_ut_hits;
    DEVICE_INPUT(dev_ut_hit_offsets_t, unsigned) dev_ut_hit_offsets;

    // Downstream
    DEVICE_INPUT(dev_offsets_downstream_hit_numbers_t, unsigned) dev_offsets_downstream_hit_numbers;
    DEVICE_INPUT(dev_offsets_downstream_tracks_t, unsigned) dev_offsets_downstream_tracks;
    DEVICE_INPUT(dev_downstream_track_states_t, char) dev_downstream_track_states;
    DEVICE_INPUT(dev_downstream_track_hits_t, char) dev_downstream_track_hits;
    DEVICE_INPUT(dev_downstream_track_scifi_idx_t, unsigned) dev_downstream_track_scifi_idx;

    // Scifi
    DEVICE_INPUT(dev_scifi_hits_t, char) dev_scifi_hits;
    DEVICE_INPUT(dev_scifi_seeds_t, SciFi::Seeding::Track) dev_scifi_seeds;
    DEVICE_INPUT(dev_offsets_scifi_seeds_t, unsigned) dev_atomics_scifi;
    DEVICE_INPUT(dev_offsets_scifi_seed_hit_number_t, unsigned) dev_scifi_seed_hit_number;
    DEVICE_INPUT(dev_seeding_states_t, MiniState) dev_seeding_states;
    DEVICE_INPUT(dev_seeding_qop_t, float) dev_seeding_qop;
    DEVICE_INPUT(dev_seeding_chi2Y_t, float) dev_seeding_chi2Y;
    // DEVICE_INPUT(dev_seeding_chi2X_t, float) dev_seeding_chi2X;
    // DEVICE_INPUT(dev_seeding_nY_t, int) dev_seeding_nY;

    // Matching input
    DEVICE_INPUT(dev_matched_is_scifi_track_used_t, bool) dev_matched_is_scifi_track_used;

    // MC
    HOST_INPUT(host_mc_events_t, const MCEvents*) host_mc_events;

    // Properties
    PROPERTY(dump_scifi_t, "dump_scifi", "dump_scifi", bool) dump_scifi;
    PROPERTY(dump_downstream_t, "dump_downstream", "dump_downstream", bool) dump_downstream;
    PROPERTY(dump_ut_hits_t, "dump_ut_hits", "dump_ut_hits", bool) dump_ut_hits;
    PROPERTY(dump_mcps_t, "dump_mcps", "dump_mcps", bool) dump_mcps;
    PROPERTY(output_folder_t, "output_folder", "output_folder", std::string) output_folder;
  };

  struct host_downstream_dump_t : public ValidationAlgorithm, Parameters {
    inline void set_arguments_size(ArgumentReferences<Parameters>, const RuntimeOptions&, const Constants&) const {}

    void operator()(
      const ArgumentReferences<Parameters>&,
      const RuntimeOptions&,
      const Constants&,
      const Allen::Context&) const;

  private:
    Property<dump_scifi_t> m_dump_scifi {this, true};
    Property<dump_downstream_t> m_dump_downstream {this, true};
    Property<dump_ut_hits_t> m_dump_ut_hits {this, true};
    Property<dump_mcps_t> m_dump_mcps {this, true};

    Property<output_folder_t> m_output_folder {this, "downstream_dump"};
  };
} // namespace host_downstream_dump