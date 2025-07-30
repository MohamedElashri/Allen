/*****************************************************************************\
* (c) Copyright 2023 CERN for the benefit of the LHCb Collaboration           *
*                                                                             *
* This software is distributed under the terms of the Apache License          *
* version 2 (Apache-2.0), copied verbatim in the file "COPYING".              *
*                                                                             *
* In applying this licence, CERN does not waive the privileges and immunities *
* granted to it by virtue of its status as an Intergovernmental Organization  *
* or submit itself to any jurisdiction.                                       *
\*****************************************************************************/
#pragma once

#include "MuonEventModel.cuh"
#include "MuonConsolidated.cuh"
#include "States.cuh"
#include "AlgorithmTypes.cuh"
#include "ParticleTypes.cuh"

namespace muon_consolidate_tracks {
  struct Parameters {
    HOST_INPUT(host_number_of_events_t, unsigned) host_number_of_events;
    HOST_INPUT(host_number_of_hits_in_muon_tracks_t, unsigned) host_number_of_hits_in_muon_tracks;
    HOST_INPUT(host_number_of_tracks_t, unsigned) host_number_of_tracks;
    MASK_INPUT(dev_event_list_t) dev_event_list;
    DEVICE_INPUT(dev_number_of_events_t, unsigned) dev_number_of_events;
    DEVICE_INPUT(dev_long_tracks_view_t, Allen::Views::Physics::MultiEventLongTracks) dev_long_tracks_view;
    DEVICE_INPUT(dev_track_offsets_t, unsigned) dev_track_offsets;
    DEVICE_INPUT(dev_muon_idxs_t, unsigned) dev_muon_idxs;
    DEVICE_INPUT(dev_muon_hit_offsets_t, unsigned) dev_muon_hit_offsets;
    DEVICE_INPUT(dev_muon_hits_data_t, char) dev_muon_hits_data;
    DEVICE_INPUT(dev_station_ocurrences_offset_t, unsigned) dev_station_ocurrences_offset;

    // Consolidated muon hits.
    DEVICE_OUTPUT(dev_consolidated_muon_hits_data_t, char) dev_consolidated_muon_hits_data;

    // Muon track views.
    DEVICE_OUTPUT_WITH_DEPENDENCIES(
      dev_muon_hits_view_t,
      DEPENDENCIES(dev_consolidated_muon_hits_data_t),
      Allen::Views::Muon::Consolidated::Hits)
    dev_muon_hits_view;
    DEVICE_OUTPUT_WITH_DEPENDENCIES(
      dev_muon_track_view_t,
      DEPENDENCIES(dev_muon_hits_view_t),
      Allen::Views::Muon::Consolidated::Track)
    dev_muon_track_view;
    DEVICE_OUTPUT_WITH_DEPENDENCIES(
      dev_muon_tracks_view_t,
      DEPENDENCIES(dev_muon_track_view_t),
      Allen::Views::Muon::Consolidated::Tracks)
    dev_muon_tracks_view;
    DEVICE_OUTPUT_WITH_DEPENDENCIES(
      dev_muon_multi_event_tracks_view_t,
      DEPENDENCIES(dev_muon_tracks_view_t),
      Allen::Views::Muon::Consolidated::MultiEventTracks)
    dev_muon_multi_event_tracks_view;

    // Long track views with muon segments.
    DEVICE_OUTPUT_WITH_DEPENDENCIES(
      dev_muon_long_track_view_t,
      DEPENDENCIES(dev_long_tracks_view_t, dev_muon_multi_event_tracks_view_t),
      Allen::Views::Physics::LongTrack)
    dev_muon_long_track_view;
    DEVICE_OUTPUT_WITH_DEPENDENCIES(
      dev_muon_long_tracks_view_t,
      DEPENDENCIES(dev_muon_long_track_view_t),
      Allen::Views::Physics::LongTracks)
    dev_muon_long_tracks_view;
    DEVICE_OUTPUT_WITH_DEPENDENCIES(
      dev_multi_event_muon_long_tracks_view_t,
      DEPENDENCIES(dev_muon_long_tracks_view_t),
      Allen::Views::Physics::MultiEventLongTracks)
    dev_multi_event_muon_long_tracks_view;
    DEVICE_OUTPUT_WITH_DEPENDENCIES(
      dev_multi_event_muon_long_tracks_ptr_t,
      DEPENDENCIES(dev_multi_event_muon_long_tracks_view_t),
      Allen::IMultiEventContainer*)
    dev_multi_event_muon_long_tracks_ptr;
  };

  __global__ void muon_consolidate_tracks(Parameters parameters);

  struct muon_consolidate_tracks_t : public DeviceAlgorithm, Parameters {
    void set_arguments_size(ArgumentReferences<Parameters> arguments, const RuntimeOptions&, const Constants&) const;

    void operator()(
      const ArgumentReferences<Parameters>& arguments,
      const RuntimeOptions&,
      const Constants&,
      const Allen::Context& context) const;

  private:
    Allen::Property<dim3> m_block_dim {this, "block_dim", {256, 1, 1}, "block dimensions"};
  };

} // namespace muon_consolidate_tracks