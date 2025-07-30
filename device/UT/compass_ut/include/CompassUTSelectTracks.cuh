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

namespace compass_ut_select_tracks {

  struct Parameters {
    HOST_INPUT(host_number_of_events_t, unsigned) host_number_of_events;
    DEVICE_INPUT(dev_number_of_events_t, unsigned) dev_number_of_events;
    MASK_INPUT(dev_event_list_t) dev_event_list;
    // UT
    DEVICE_INPUT(dev_ut_hit_offsets_t, unsigned) dev_ut_hit_offsets;
    // From candidates
    DEVICE_INPUT(dev_ut_track_consolidate_candidate_offset_t, unsigned) dev_ut_track_consolidate_candidate_offset;
    HOST_INPUT(host_number_of_ut_track_output_tracks_t, unsigned) host_number_of_ut_track_output_tracks;
    DEVICE_INPUT(dev_ut_track_output_offset_t, unsigned) dev_ut_track_output_offset;
    DEVICE_INPUT(dev_ut_track_output_tracks_t, CompassUT::Structs::VeloUTTrack) dev_ut_track_output_tracks;
    // Temporary
    DEVICE_OUTPUT(dev_ut_track_selection_t, int8_t) dev_ut_track_selection;
    // Best output
    HOST_OUTPUT(host_number_of_ut_track_selected_tracks_t, unsigned) host_number_of_ut_track_selected_tracks;
    DEVICE_OUTPUT(dev_ut_track_selected_offset_t, unsigned) dev_ut_track_selected_offset;
    DEVICE_OUTPUT(dev_ut_track_selected_tracks_t, CompassUT::Structs::VeloUTTrack) dev_ut_track_selected_tracks;
  };

  __global__ void compass_ut_kill_clone_tracks(Parameters, int min_independent_hits, float vp_clone_killing_threshold);

  struct compass_ut_select_tracks_t : public DeviceAlgorithm, Parameters {
    void set_arguments_size(ArgumentReferences<Parameters> arguments, const RuntimeOptions&, const Constants&) const;

    void operator()(
      const ArgumentReferences<Parameters>& arguments,
      const RuntimeOptions&,
      const Constants& constants,
      const Allen::Context& context) const;

  private:
    Allen::Property<dim3> m_block_dim {this, "block_dim", {256, 1, 1}, "block dimensions"};
    Allen::Property<int> m_min_independent_hits {this,
                                                 "min_independent_hits",
                                                 2,
                                                 "minimum number of independent ut hits"};
    Allen::Property<float> m_vp_clone_killing_threshold {
      this,
      "vp_clone_killing_threshold",
      0.2,
      "the threshold for vp clone killing, only killed candidates with | score - best_score | > threshold "};
  };
} // namespace compass_ut_select_tracks
