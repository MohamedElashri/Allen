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

namespace compass_ut_find_tracks {
  struct Parameters {
    HOST_INPUT(host_number_of_events_t, unsigned) host_number_of_events;
    DEVICE_INPUT(dev_number_of_events_t, unsigned) dev_number_of_events;
    DEVICE_INPUT(dev_ut_hits_t, char) dev_ut_hits;
    DEVICE_INPUT(dev_ut_hit_offsets_t, unsigned) dev_ut_hit_offsets;
    DEVICE_INPUT(dev_velo_tracks_view_t, Allen::Views::Velo::Consolidated::Tracks) dev_velo_tracks_view;
    DEVICE_INPUT(dev_velo_states_view_t, Allen::Views::Physics::KalmanStates) dev_velo_states_view;
    MASK_INPUT(dev_event_list_t) dev_event_list;
    // From candidates
    HOST_INPUT(host_number_of_ut_track_candidate_t, unsigned) host_number_of_ut_track_candidate;
    DEVICE_INPUT(dev_ut_track_consolidate_candidate_offset_t, unsigned) dev_ut_track_consolidate_candidate_offset;
    DEVICE_INPUT(dev_ut_track_consolidate_candidates_t, CompassUT::Structs::Candidate)
    dev_ut_track_consolidate_candidates;
    // Output
    HOST_OUTPUT(host_number_of_ut_track_output_tracks_t, unsigned) host_number_of_ut_track_output_tracks;
    DEVICE_OUTPUT(dev_ut_track_output_offset_t, unsigned) dev_ut_track_output_offset;
    DEVICE_OUTPUT(dev_ut_track_output_tracks_t, CompassUT::Structs::VeloUTTrack) dev_ut_track_output_tracks;
  };

  __global__ void compass_ut_find_tracks(
    Parameters,
    UTMagnetTool* dev_ut_magnet_tool,
    const UT::Constants::UTLayerGeometry* dev_ut_layer_geometry,
    float xtol_axial,
    float xtol_stereo,
    float ytol);

  struct compass_ut_find_tracks_t : public DeviceAlgorithm, Parameters {
    void set_arguments_size(ArgumentReferences<Parameters> arguments, const RuntimeOptions&, const Constants&) const;

    void operator()(
      const ArgumentReferences<Parameters>& arguments,
      const RuntimeOptions&,
      const Constants& constants,
      const Allen::Context& context) const;

  private:
    Allen::Property<float> m_xtol_axial {this, "xtol_axial", 2.f, "x tolerance window for axial layers [mm]"};
    Allen::Property<float> m_xtol_stereo {this, "xtol_stereo", 4.f, "x tolerance window for stereo layers [mm]"};
    Allen::Property<float> m_ytol {this, "ytol", 1.f, "y tolerance window [mm]"};
    Allen::Property<dim3> m_block_dim {this, "block_dim", {256, 1, 1}, "block dimensions"};
  };
} // namespace compass_ut_find_tracks
