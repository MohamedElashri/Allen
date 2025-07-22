/*****************************************************************************\
* (c) Copyright 2024 CERN for the benefit of the LHCb Collaboration           *
*                                                                             *
* This software is distributed under the terms of the Apache License          *
* version 2 (Apache-2.0), copied verbatim in the file "LICENSE".              *
*                                                                             *
* In applying this licence, CERN does not waive the privileges and immunities *
* granted to it by virtue of its status as an Intergovernmental Organization  *
* or submit itself to any jurisdiction.                                       *
\*****************************************************************************/
#pragma once

#include "UTDefinitions.cuh"
#include "UTEventModel.cuh"
#include "VeloConsolidated.cuh"
#include "UTMagnetToolDefinitions.h"
#include "CompassUTStructs.cuh"
#include "AlgorithmTypes.cuh"
#include "SingleLayerFCNN.cuh"

namespace compass_ut_fit_tracks {

  using VeloUTGhostKiller = Allen::MVAModels::SingleLayerFCNN<4, 8>;

  struct Parameters {
    HOST_INPUT(host_number_of_events_t, unsigned) host_number_of_events;
    DEVICE_INPUT(dev_number_of_events_t, unsigned) dev_number_of_events;
    DEVICE_INPUT(dev_ut_hits_t, char) dev_ut_hits;
    DEVICE_INPUT(dev_ut_hit_offsets_t, unsigned) dev_ut_hit_offsets;
    DEVICE_INPUT(dev_velo_tracks_view_t, Allen::Views::Velo::Consolidated::Tracks) dev_velo_tracks_view;
    DEVICE_INPUT(dev_velo_states_view_t, Allen::Views::Physics::KalmanStates) dev_velo_states_view;
    MASK_INPUT(dev_event_list_t) dev_event_list;
    // From candidates
    HOST_INPUT(host_number_of_ut_track_selected_tracks_t, unsigned) host_number_of_ut_track_selected_tracks;
    DEVICE_INPUT(dev_ut_track_output_offset_t, unsigned) dev_ut_track_output_offset;
    DEVICE_INPUT(dev_ut_track_selected_offset_t, unsigned) dev_ut_track_selected_offset;
    DEVICE_INPUT(dev_ut_track_selected_tracks_t, CompassUT::Structs::VeloUTTrack) dev_ut_track_selected_tracks;
    // Output
    HOST_OUTPUT(host_number_of_ut_track_hits_t, unsigned) host_number_of_ut_tracks;
    DEVICE_OUTPUT(dev_ut_track_hits_offset_t, unsigned) dev_ut_track_hits_offset;
    DEVICE_OUTPUT(dev_ut_track_hits_t, UT::TrackHits) dev_ut_track_hits;
  };

  __global__ void compass_ut_fit_tracks(
    Parameters,
    UTMagnetTool* dev_ut_magnet_tool,
    const VeloUTGhostKiller::DeviceType* dev_velout_ghostkiller_3hits,
    const VeloUTGhostKiller::DeviceType* dev_velout_ghostkiller_4hits,
    float sigma_velo_slope,
    float min_momentum_final,
    float min_pt_final,
    float min_ghost_prob_3_hit,
    float min_ghost_prob_4_hit);

  struct compass_ut_fit_tracks_t : public DeviceAlgorithm, Parameters {
    void set_arguments_size(ArgumentReferences<Parameters> arguments, const RuntimeOptions&, const Constants&) const;

    void operator()(
      const ArgumentReferences<Parameters>& arguments,
      const RuntimeOptions&,
      const Constants& constants,
      const Allen::Context& context) const;

  private:
    Allen::Property<float> m_sigma_velo_slope {this,
                                               "sigma_velo_slope",
                                               0.1f * Allen::Units::mrad,
                                               "sigma velo slope [radians]"};
    Allen::Property<float> m_min_momentum_final {this, "min_momentum_final", 2500.f, "final min momentum cut [MeV/c]"};
    Allen::Property<float> m_min_pt_final {this, "min_pt_final", 425.f, "final min pT cut [MeV/c]"};
    Allen::Property<float> m_min_ghost_prob_3_hit {this, "min_ghost_prob_3_hit", 0.5f, "min_ghost_prob_3_hit"};
    Allen::Property<float> m_min_ghost_prob_4_hit {this, "min_ghost_prob_4_hit", 0.5f, "min_ghost_prob_4_hit"};
    Allen::Property<dim3> m_block_dim {this, "block_dim", {256, 1, 1}, "block dimensions"};

  private:
    VeloUTGhostKiller m_dev_velout_ghostkiller_3hits {"dev_velout_ghostkiller_3hits",
                                                      "/GhostProbability/Hlt1_VeloUTGhostKiller_3Hits.json"};
    VeloUTGhostKiller m_dev_velout_ghostkiller_4hits {"dev_velout_ghostkiller_4hits",
                                                      "/GhostProbability/Hlt1_VeloUTGhostKiller_4Hits.json"};
  };
} // namespace compass_ut_fit_tracks
