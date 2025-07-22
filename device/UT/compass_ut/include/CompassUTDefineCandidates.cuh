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
#include "VeloConsolidated.cuh"
#include "UTMagnetToolDefinitions.h"
#include "CompassUTStructs.cuh"
#include "AlgorithmTypes.cuh"

namespace compass_ut_define_candidates {
  struct Parameters {
    HOST_INPUT(host_number_of_events_t, unsigned) host_number_of_events;
    DEVICE_INPUT(dev_number_of_events_t, unsigned) dev_number_of_events;
    MASK_INPUT(dev_event_list_t) dev_event_list;
    // UT hits
    DEVICE_INPUT(dev_ut_hits_t, char) dev_ut_hits;
    DEVICE_INPUT(dev_ut_hit_offsets_t, unsigned) dev_ut_hit_offsets;
    // Velo input
    DEVICE_INPUT(dev_offsets_all_velo_tracks_t, unsigned) dev_offsets_all_velo_tracks;
    DEVICE_INPUT(dev_velo_states_view_t, Allen::Views::Physics::KalmanStates) dev_velo_states_view;
    // Velo seletion
    HOST_INPUT(host_ut_number_of_selected_velo_tracks_t, unsigned) host_ut_number_of_selected_velo_tracks;
    DEVICE_INPUT(dev_ut_selected_velo_tracks_offsets_t, unsigned) dev_ut_selected_velo_tracks_offsets;
    DEVICE_INPUT(dev_ut_selected_velo_tracks_t, unsigned) dev_ut_selected_velo_tracks;
    // Preselection
    DEVICE_OUTPUT(dev_ut_track_candidate_tols_t, float2) dev_ut_track_candidate_tols;
    DEVICE_OUTPUT(dev_ut_track_candidate_hit_ranges_t, CompassUT::Structs::LayerHitRanges)
    dev_ut_track_candidate_hit_ranges;
    // All cnadidates
    DEVICE_OUTPUT(dev_ut_track_all_candidate_input_offset_t, unsigned) dev_ut_track_all_candidate_input_offset;
    DEVICE_OUTPUT(dev_ut_track_all_candidate_output_offset_t, unsigned) dev_ut_track_all_candidate_output_offset;
    DEVICE_OUTPUT(dev_ut_track_all_candidates_t, CompassUT::Structs::Candidate) dev_ut_track_all_candidates;
    // Consolidate outputs
    HOST_OUTPUT(host_number_of_ut_track_candidate_t, unsigned) host_number_of_ut_track_candidate;
    DEVICE_OUTPUT(dev_ut_track_consolidate_candidate_offset_t, unsigned) dev_ut_track_consolidate_candidate_offset;
    DEVICE_OUTPUT(dev_ut_track_consolidate_candidates_t, CompassUT::Structs::Candidate)
    dev_ut_track_consolidate_candidates;
  };

  __global__ void compass_ut_hit_preselection(
    Parameters,
    UTMagnetTool* dev_ut_magnet_tool,
    const UT::Constants::UTLayerGeometry* dev_ut_layer_geometry,
    float min_momentum,
    float min_pt,
    float y_tol,
    float y_tol_slope);

  __global__ void compass_ut_fill_cadidates(Parameters, float y_tol, float y_tol_slope);

  __global__ void compass_ut_consolidate_candidates(Parameters);

  struct compass_ut_define_candidates_t : public DeviceAlgorithm, Parameters {
    void set_arguments_size(ArgumentReferences<Parameters> arguments, const RuntimeOptions&, const Constants&) const;

    void operator()(
      const ArgumentReferences<Parameters>& arguments,
      const RuntimeOptions&,
      const Constants& constants,
      const Allen::Context& context) const;

  private:
    Allen::Property<float> m_min_momentum {this,
                                           "min_momentum",
                                           1500.f * Allen::Units::MeV,
                                           "min momentum cut [MeV/c]"};
    Allen::Property<float> m_min_pt {this, "min_pt", 300.f * Allen::Units::MeV, "min pT cut [MeV/c]"};
    Allen::Property<float> m_y_tol {this, "y_tol", 0.5f * Allen::Units::mm, "y tol [mm]"};
    Allen::Property<float> m_y_tol_slope {this, "y_tol_slope", 0.08f, "y tol slope [mm]"};
    Allen::Property<dim3> m_block_dim {this, "block_dim", {256, 1, 1}, "block dimensions"};
  };
} // namespace compass_ut_define_candidates
