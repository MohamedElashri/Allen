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
#include "ConsolidateIsMuon.cuh"
#include "MuonDefinitions.cuh"
#include "MuonEventModel.cuh"
#include "MuonTileID.cuh"

INSTANTIATE_ALGORITHM(muon_consolidate_tracks::muon_consolidate_tracks_t)

__global__ void create_muon_views(muon_consolidate_tracks::Parameters parameters)
{
  const unsigned number_of_events = parameters.dev_number_of_events[0];
  const unsigned event_number = blockIdx.x;

  const auto event_tracks = parameters.dev_long_tracks_view->container(event_number);
  const unsigned event_tracks_offset = event_tracks.offset();
  const unsigned n_tracks = event_tracks.size();

  for (unsigned track_index = threadIdx.x; track_index < n_tracks; track_index += blockDim.x) {
    const auto long_track = event_tracks.track(track_index);
    const auto n_muon_hits = parameters.dev_muon_hit_offsets[event_tracks_offset + track_index + 1] -
                             parameters.dev_muon_hit_offsets[event_tracks_offset + track_index];

    new (parameters.dev_muon_track_view + event_tracks_offset + track_index)
      Allen::Views::Muon::Consolidated::Track {parameters.dev_muon_hits_view,
                                               parameters.dev_track_offsets,
                                               parameters.dev_muon_hit_offsets,
                                               track_index,
                                               event_number};
    // Only include the muon segment if there is at least one muon hit.
    if (n_muon_hits > 0) {
      new (parameters.dev_muon_long_track_view + event_tracks_offset + track_index)
        Allen::Views::Physics::LongTrack {long_track.track_segment_ptr<Allen::Views::Physics::Track::segment::velo>(),
                                          long_track.track_segment_ptr<Allen::Views::Physics::Track::segment::ut>(),
                                          long_track.track_segment_ptr<Allen::Views::Physics::Track::segment::scifi>(),
                                          parameters.dev_muon_track_view + event_tracks_offset + track_index,
                                          long_track.qop_ptr(),
                                          long_track.ghost_probability_ptr()};
    }
    else {
      new (parameters.dev_muon_long_track_view + event_tracks_offset + track_index)
        Allen::Views::Physics::LongTrack {long_track.track_segment_ptr<Allen::Views::Physics::Track::segment::velo>(),
                                          long_track.track_segment_ptr<Allen::Views::Physics::Track::segment::ut>(),
                                          long_track.track_segment_ptr<Allen::Views::Physics::Track::segment::scifi>(),
                                          nullptr,
                                          long_track.qop_ptr(),
                                          long_track.ghost_probability_ptr()};
    }
  }

  if (threadIdx.x == 0) {
    new (parameters.dev_muon_hits_view + event_number)
      Allen::Views::Muon::Consolidated::Hits {parameters.dev_consolidated_muon_hits_data,
                                              parameters.dev_track_offsets,
                                              parameters.dev_muon_hit_offsets,
                                              event_number,
                                              number_of_events};

    new (parameters.dev_muon_tracks_view + event_number) Allen::Views::Muon::Consolidated::Tracks {
      parameters.dev_muon_track_view, parameters.dev_track_offsets, event_number};

    new (parameters.dev_muon_long_tracks_view + event_number) Allen::Views::Physics::LongTracks {
      parameters.dev_muon_long_track_view, parameters.dev_track_offsets, event_number};
  }

  if (blockIdx.x == 0 && threadIdx.x == 0) {
    new (parameters.dev_muon_multi_event_tracks_view)
      Allen::Views::Muon::Consolidated::MultiEventTracks {parameters.dev_muon_tracks_view, number_of_events};
    new (parameters.dev_multi_event_muon_long_tracks_view)
      Allen::Views::Physics::MultiEventLongTracks {parameters.dev_muon_long_tracks_view, number_of_events};
    parameters.dev_multi_event_muon_long_tracks_ptr[0] = parameters.dev_multi_event_muon_long_tracks_view.data();
  }
}

void muon_consolidate_tracks::muon_consolidate_tracks_t::set_arguments_size(
  ArgumentReferences<Parameters> arguments,
  const RuntimeOptions&,
  const Constants&) const
{
  auto n_tracks = first<host_number_of_tracks_t>(arguments);
  auto n_hits = first<host_number_of_hits_in_muon_tracks_t>(arguments);
  auto n_events = first<host_number_of_events_t>(arguments);
  set_size<dev_consolidated_muon_hits_data_t>(arguments, n_hits * Muon::Hits::element_size);
  set_size<dev_muon_hits_view_t>(arguments, n_events);
  set_size<dev_muon_track_view_t>(arguments, n_tracks);
  set_size<dev_muon_tracks_view_t>(arguments, n_events);
  set_size<dev_muon_multi_event_tracks_view_t>(arguments, 1);
  set_size<dev_muon_long_track_view_t>(arguments, n_tracks);
  set_size<dev_muon_long_tracks_view_t>(arguments, n_events);
  set_size<dev_multi_event_muon_long_tracks_view_t>(arguments, 1);
  set_size<dev_multi_event_muon_long_tracks_ptr_t>(arguments, 1);
}

void muon_consolidate_tracks::muon_consolidate_tracks_t::operator()(
  const ArgumentReferences<Parameters>& arguments,
  const RuntimeOptions&,
  const Constants&,
  const Allen::Context& context) const
{
  Allen::memset_async<dev_muon_multi_event_tracks_view_t>(arguments, 0, context);
  Allen::memset_async<dev_muon_tracks_view_t>(arguments, 0, context);
  Allen::memset_async<dev_multi_event_muon_long_tracks_view_t>(arguments, 0, context);
  Allen::memset_async<dev_muon_long_tracks_view_t>(arguments, 0, context);

  global_function(muon_consolidate_tracks::muon_consolidate_tracks)(
    dim3(size<dev_event_list_t>(arguments)), m_block_dim, context)(arguments);
  global_function(create_muon_views)(first<host_number_of_events_t>(arguments), 256, context)(arguments);
}

template<typename F>
__device__ void populate(const unsigned* idxs, const unsigned n_hits, const F& assign)
{
  for (unsigned i = 0; i < n_hits; i++) {
    const auto hit_index = idxs[i];
    assign(i, hit_index);
  }
}

__global__ void muon_consolidate_tracks::muon_consolidate_tracks(muon_consolidate_tracks::Parameters parameters)
{
  const unsigned event_number = parameters.dev_event_list[blockIdx.x];
  const unsigned number_of_events = parameters.dev_number_of_events[0];

  const auto event_tracks = parameters.dev_long_tracks_view->container(event_number);
  const unsigned n_tracks = event_tracks.size();
  const unsigned tracks_offset = event_tracks.offset();

  const auto muon_total_number_of_hits =
    parameters.dev_station_ocurrences_offset[number_of_events * Muon::Constants::n_stations];
  const auto muon_hits = Muon::ConstHits {parameters.dev_muon_hits_data, muon_total_number_of_hits};

  const auto muon_total_number_of_consolidated_hits =
    parameters.dev_muon_hit_offsets[parameters.dev_long_tracks_view->number_of_contained_objects()];
  auto consolidated_muon_hits =
    Muon::Hits {parameters.dev_consolidated_muon_hits_data, muon_total_number_of_consolidated_hits};

  for (unsigned i_track = threadIdx.x; i_track < n_tracks; i_track += blockDim.x) {
    const unsigned muon_offset = Muon::Constants::max_hits_per_track * (tracks_offset + i_track);
    const unsigned consolidated_muon_offset = parameters.dev_muon_hit_offsets[tracks_offset + i_track];
    const unsigned n_muon_hits =
      parameters.dev_muon_hit_offsets[tracks_offset + i_track + 1] - consolidated_muon_offset;
    const unsigned* track_idxs = parameters.dev_muon_idxs + muon_offset;

    populate(
      track_idxs,
      n_muon_hits,
      [&consolidated_muon_hits, &muon_hits, &consolidated_muon_offset](const unsigned i, const unsigned hit_idx) {
        consolidated_muon_hits.x(consolidated_muon_offset + i) = muon_hits.x(hit_idx);
      });

    populate(
      track_idxs,
      n_muon_hits,
      [&consolidated_muon_hits, &muon_hits, &consolidated_muon_offset](const unsigned i, const unsigned hit_idx) {
        consolidated_muon_hits.dx(consolidated_muon_offset + i) = muon_hits.dx(hit_idx);
      });

    populate(
      track_idxs,
      n_muon_hits,
      [&consolidated_muon_hits, &muon_hits, &consolidated_muon_offset](const unsigned i, const unsigned hit_idx) {
        consolidated_muon_hits.y(consolidated_muon_offset + i) = muon_hits.y(hit_idx);
      });

    populate(
      track_idxs,
      n_muon_hits,
      [&consolidated_muon_hits, &muon_hits, &consolidated_muon_offset](const unsigned i, const unsigned hit_idx) {
        consolidated_muon_hits.dy(consolidated_muon_offset + i) = muon_hits.dy(hit_idx);
      });

    populate(
      track_idxs,
      n_muon_hits,
      [&consolidated_muon_hits, &muon_hits, &consolidated_muon_offset](const unsigned i, const unsigned hit_idx) {
        consolidated_muon_hits.z(consolidated_muon_offset + i) = muon_hits.z(hit_idx);
      });
    populate(
      track_idxs,
      n_muon_hits,
      [&consolidated_muon_hits, &muon_hits, &consolidated_muon_offset](const unsigned i, const unsigned hit_idx) {
        consolidated_muon_hits.time(consolidated_muon_offset + i) = muon_hits.time(hit_idx);
      });

    populate(
      track_idxs,
      n_muon_hits,
      [&consolidated_muon_hits, &muon_hits, &consolidated_muon_offset](const unsigned i, const unsigned hit_idx) {
        consolidated_muon_hits.tile(consolidated_muon_offset + i) = muon_hits.tile(hit_idx);
      });

    populate(
      track_idxs,
      n_muon_hits,
      [&consolidated_muon_hits, &muon_hits, &consolidated_muon_offset](const unsigned i, const unsigned hit_idx) {
        consolidated_muon_hits.uncrossed(consolidated_muon_offset + i) = muon_hits.uncrossed(hit_idx);
      });

    populate(
      track_idxs,
      n_muon_hits,
      [&consolidated_muon_hits, &muon_hits, &consolidated_muon_offset](const unsigned i, const unsigned hit_idx) {
        consolidated_muon_hits.delta_time(consolidated_muon_offset + i) = muon_hits.delta_time(hit_idx);
      });

    populate(
      track_idxs,
      n_muon_hits,
      [&consolidated_muon_hits, &muon_hits, &consolidated_muon_offset](const unsigned i, const unsigned hit_idx) {
        consolidated_muon_hits.region(consolidated_muon_offset + i) = muon_hits.region(hit_idx);
      });
  }
}
