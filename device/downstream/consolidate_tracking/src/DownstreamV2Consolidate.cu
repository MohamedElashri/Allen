/*****************************************************************************\
* (c) Copyright 2024 CERN for the benefit of the LHCb Collaboration          *
*                                                                             *
* This software is distributed under the terms of the Apache License          *
* version 2 (Apache-2.0), copied verbatim in the file "LICENSE".              *
*                                                                             *
* In applying this licence, CERN does not waive the privileges and immunities *
* granted to it by virtue of its status as an Intergovernmental Organization  *
* or submit itself to any jurisdiction.                                       *
\*****************************************************************************/

#include "DownstreamV2Consolidate.cuh"
#include "DownstreamV2Constants.cuh"

INSTANTIATE_ALGORITHM(downstream_v2_consolidate::downstream_v2_consolidate_t)

namespace {

  template<typename F>
  __device__ void populate(const Downstream::Structs::CompactTrack& track, const F& assign)
  {
    for (unsigned i = 0; i < 4; i++) {
      const auto hit_index = track.ut_hits[i];
      assign(i, hit_index);
    }
  }
} // namespace

void downstream_v2_consolidate::downstream_v2_consolidate_t::set_arguments_size(
  ArgumentReferences<Parameters> arguments,
  const RuntimeOptions&,
  const Constants&) const
{
  // Basics
  const auto number_of_hits = first<host_number_of_downstream_hits_t>(arguments);
  const auto number_of_tracks = first<host_number_of_downstream_tracks_t>(arguments);
  const auto number_of_events = first<host_number_of_events_t>(arguments);

  // Consolidated objects
  set_size<dev_downstream_track_states_t>(arguments, number_of_tracks * Velo::Consolidated::States::size);
  set_size<dev_downstream_track_hits_t>(arguments, number_of_hits * UT::Consolidated::Hits::element_size);
  set_size<dev_downstream_track_qops_t>(arguments, number_of_tracks);
  set_size<dev_downstream_track_ghost_probability_t>(arguments, number_of_tracks);
  set_size<dev_downstream_track_scifi_indices_t>(arguments, number_of_tracks);
  set_size<dev_downstream_track_scifi_states_t>(arguments, number_of_tracks);

  // Views (UT hits)
  set_size<dev_downstream_hits_view_t>(arguments, number_of_events);

  // Views (UT tracks)
  set_size<dev_downstream_ut_track_view_t>(arguments, number_of_tracks);
  set_size<dev_downstream_ut_tracks_view_t>(arguments, number_of_events);
  set_size<dev_multi_event_downstream_ut_tracks_view_t>(arguments, 1u);
  set_size<dev_multi_event_downstream_ut_tracks_view_ptr_t>(arguments, 1u);

  // Views (UT+SciFi tracks)
  set_size<dev_downstream_track_view_t>(arguments, number_of_tracks);
  set_size<dev_downstream_tracks_view_t>(arguments, number_of_events);
  set_size<dev_multi_event_downstream_tracks_view_t>(arguments, 1u);
  set_size<dev_multi_event_downstream_tracks_view_ptr_t>(arguments, 1u);

  // Views (states)
  set_size<dev_downstream_track_states_view_t>(arguments, number_of_events);
}

void downstream_v2_consolidate::downstream_v2_consolidate_t::operator()(
  const ArgumentReferences<Parameters>& arguments,
  const RuntimeOptions&,
  const Constants&,
  const Allen::Context& context) const
{
  Allen::memset_async<dev_downstream_track_hits_t>(arguments, 0, context);

  // Consolidate
  global_function(downstream_v2_consolidate_tracks)(dim3(size<dev_event_list_t>(arguments)), m_block_dim, context)(
    arguments);

  // Create views
  global_function(downstream_v2_create_track_views)(
    dim3(first<host_number_of_events_t>(arguments)), dim3(256), context)(arguments);

  // Monitoring
  global_function(downstream_v2_track_monitoring)(dim3(first<host_number_of_events_t>(arguments)), dim3(256), context)(
    arguments,
    m_downstream_tracks.data(context),
    m_histogram_n_downstream_tracks.data(context),
    m_histogram_downstream_track_eta.data(context),
    m_histogram_downstream_track_phi.data(context),
    m_histogram_downstream_track_nhits.data(context));
}

__global__ void downstream_v2_consolidate::downstream_v2_consolidate_tracks(Parameters parameters)
{
  // Alias
  // using Downstream::Constants::MaxNumCandidatesPerSeed;

  // Basics
  const unsigned event_number = parameters.dev_event_list[blockIdx.x];
  const unsigned number_of_events = parameters.dev_number_of_events[0];

  // Make offsets
  const auto input_offset = parameters.dev_downstream_compact_track_input_offsets[event_number];
  const auto output_offset = parameters.dev_downstream_track_offsets[event_number];
  const auto input_size = parameters.dev_downstream_track_offsets[event_number + 1] - output_offset;
  const auto track_hits_offset = parameters.dev_downstream_track_hit_offsets[output_offset];

  const auto total_number_of_tracks = parameters.dev_downstream_track_offsets[number_of_events];
  const auto total_number_of_track_hits = parameters.dev_downstream_track_hit_offsets[total_number_of_tracks];

  // Inputs
  const auto input_tracks = parameters.dev_downstream_compact_tracks + input_offset;
  const auto input_states = parameters.dev_downstream_compact_track_states + input_offset;
  const auto input_scores = parameters.dev_downstream_compact_track_scores + input_offset;
  const auto input_qops = parameters.dev_downstream_compact_track_qops + input_offset;
  const auto input_scifi_states = parameters.dev_scifi_states.data();

  // UT hits
  const unsigned total_number_of_ut_hits = parameters.dev_ut_hit_offsets[number_of_events * UT::Constants::n_groups];
  const UT::HitOffsets ut_hit_offsets {parameters.dev_ut_hit_offsets, event_number};
  UT::ConstHits ut_hits {parameters.dev_ut_hits, total_number_of_ut_hits, ut_hit_offsets.event_offset()};

  // Prepare output containers
  UT::Consolidated::Hits output_track_hits(
    parameters.dev_downstream_track_hits, track_hits_offset, total_number_of_track_hits);

  Velo::Consolidated::States output_states(
    parameters.dev_downstream_track_states, total_number_of_tracks, output_offset);

  auto output_qops = parameters.dev_downstream_track_qops + output_offset;
  auto output_ghost_probabilities = parameters.dev_downstream_track_ghost_probability + output_offset;
  auto output_scifi_indices = parameters.dev_downstream_track_scifi_indices + output_offset;
  auto output_scifi_states = parameters.dev_downstream_track_scifi_states + output_offset;

  // Fill outputs
  for (unsigned reconstructed_idx = threadIdx.x; reconstructed_idx < input_size; reconstructed_idx += blockDim.x) {
    // Fetch input
    const auto input_track = input_tracks[reconstructed_idx];
    const auto input_state = input_states[reconstructed_idx];
    const auto input_score = input_scores[reconstructed_idx];
    const auto input_qop = input_qops[reconstructed_idx];

    // Fill outputs
    output_qops[reconstructed_idx] = input_qop;
    output_ghost_probabilities[reconstructed_idx] = input_score;
    output_scifi_indices[reconstructed_idx] = input_track.scifi_idx;
    output_scifi_states[reconstructed_idx] = input_scifi_states[input_track.scifi_idx];

    // Fill state
    output_states.x(reconstructed_idx) = input_state.x();
    output_states.y(reconstructed_idx) = input_state.y();
    output_states.z(reconstructed_idx) = input_state.z();
    output_states.tx(reconstructed_idx) = input_state.tx();
    output_states.ty(reconstructed_idx) = input_state.ty();
    output_states.qop(reconstructed_idx) = input_qop;
    output_states.chi2(reconstructed_idx) = input_score;
    output_states.ndof(reconstructed_idx) = 1;

    // Fill hits
    const auto output_hit_offset = reconstructed_idx * 4;
    for (unsigned i = 0; i < 4; i++) {
      const auto output_hit_idx = output_hit_offset + i;
      const auto input_hit_idx = input_track.ut_hits[i];
      output_track_hits.yBegin(output_hit_idx) = ut_hits.yBegin(input_hit_idx);
      output_track_hits.yEnd(output_hit_idx) = ut_hits.yEnd(input_hit_idx);
      output_track_hits.zAtYEq0(output_hit_idx) = ut_hits.zAtYEq0(input_hit_idx);
      output_track_hits.xAtYEq0(output_hit_idx) = ut_hits.xAtYEq0(input_hit_idx);
      output_track_hits.dxDy(output_hit_idx) = ut_hits.dxDy(input_hit_idx);
      output_track_hits.weight(output_hit_idx) = ut_hits.weight(input_hit_idx);
      output_track_hits.id(output_hit_idx) = ut_hits.id(input_hit_idx);
      output_track_hits.plane_code(output_hit_idx) = i;
    }
  }
}

__global__ void downstream_v2_consolidate::downstream_v2_create_track_views(Parameters parameters)
{
  // Basic
  const unsigned event_number = blockIdx.x;
  const unsigned number_of_events = parameters.dev_number_of_events[0];

  // Offsets
  const auto offset = parameters.dev_downstream_track_offsets[event_number];
  const auto size = parameters.dev_downstream_track_offsets[event_number + 1] - offset;

  //
  // Make all tracks
  //
  for (unsigned track_idx = threadIdx.x; track_idx < size; track_idx += blockDim.x) {
    const auto idx = offset + track_idx;
    // UT only track
    new (parameters.dev_downstream_ut_track_view + idx)
      Allen::Views::UT::Consolidated::Track {parameters.dev_downstream_hits_view,
                                             parameters.dev_downstream_track_offsets,
                                             parameters.dev_downstream_track_hit_offsets,
                                             track_idx,
                                             event_number};
    // UT+SciFi track
    new (parameters.dev_downstream_track_view + idx) Allen::Views::Physics::DownstreamTrack {
      parameters.dev_downstream_ut_track_view + idx,
      parameters.dev_scifi_track_view + parameters.dev_downstream_track_scifi_indices[idx],
      parameters.dev_downstream_track_qops + idx,
      parameters.dev_downstream_track_ghost_probability + idx};
  }

  //
  // Make containers
  //
  if (threadIdx.x == 0) {
    // Hits container
    new (parameters.dev_downstream_hits_view + event_number)
      Allen::Views::UT::Consolidated::Hits {parameters.dev_downstream_track_hits,
                                            parameters.dev_downstream_track_offsets,
                                            parameters.dev_downstream_track_hit_offsets,
                                            event_number,
                                            number_of_events};
    // UT tracks container
    new (parameters.dev_downstream_ut_tracks_view + event_number) Allen::Views::UT::Consolidated::Tracks {
      parameters.dev_downstream_ut_track_view, parameters.dev_downstream_track_offsets, event_number};
    // UT+SciFi trakcs container
    new (parameters.dev_downstream_tracks_view + event_number) Allen::Views::Physics::DownstreamTracks {
      parameters.dev_downstream_track_view, parameters.dev_downstream_track_offsets, event_number};
    // State container
    new (parameters.dev_downstream_track_states_view + event_number) Allen::Views::Physics::KalmanStates {
      parameters.dev_downstream_track_states, parameters.dev_downstream_track_offsets, event_number, number_of_events};
  }

  // Make multi-event containers
  if (blockIdx.x == 0 && threadIdx.x == 0) {
    // UT tracks
    new (parameters.dev_multi_event_downstream_ut_tracks_view)
      Allen::Views::UT::Consolidated::MultiEventTracks {parameters.dev_downstream_ut_tracks_view, number_of_events};
    parameters.dev_multi_event_downstream_ut_tracks_view_ptr[0] = parameters.dev_multi_event_downstream_ut_tracks_view;

    // UT+SciFi tracks
    new (parameters.dev_multi_event_downstream_tracks_view)
      Allen::Views::Physics::MultiEventDownstreamTracks {parameters.dev_downstream_tracks_view, number_of_events};
    parameters.dev_multi_event_downstream_tracks_view_ptr[0] = parameters.dev_multi_event_downstream_tracks_view;
  }
}

__global__ void downstream_v2_consolidate::downstream_v2_track_monitoring(
  Parameters parameters,
  Allen::Monitoring::AveragingCounter<>::DeviceType n_downstream_tracks,
  Allen::Monitoring::Histogram<>::DeviceType n_downstream_tracks_event,
  Allen::Monitoring::Histogram<>::DeviceType downstream_track_eta,
  Allen::Monitoring::Histogram<>::DeviceType downstream_track_phi,
  Allen::Monitoring::Histogram<>::DeviceType downstream_track_nhits)
{
  // Basic
  const unsigned event_number = blockIdx.x;

  // Fetch states
  const auto tracks = parameters.dev_downstream_tracks_view[event_number];
  const auto states = parameters.dev_downstream_track_states_view[event_number];
  const auto number_of_tracks = tracks.size();

  // Fill
  for (unsigned i = threadIdx.x; i < number_of_tracks; i += blockDim.x) {
    const auto state = states.state(i);
    const auto track = tracks.track(i);
    const auto tx = state.tx();
    const auto ty = state.ty();
    const auto rho = hypotf(tx, ty);
    const auto eta = eta_from_rho(rho);
    const auto phi = std::atan2(ty, tx);
    downstream_track_eta.increment(eta);
    downstream_track_phi.increment(phi);
    downstream_track_nhits.increment(track.number_of_hits());
  }
  if (threadIdx.x == 0) {
    n_downstream_tracks_event.increment(number_of_tracks);
    n_downstream_tracks.add(number_of_tracks);
  }
}
