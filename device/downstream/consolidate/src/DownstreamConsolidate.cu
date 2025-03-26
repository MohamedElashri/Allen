/*****************************************************************************\
* (c) Copyright 2022 CERN for the benefit of the LHCb Collaboration          *
*                                                                             *
* This software is distributed under the terms of the Apache License          *
* version 2 (Apache-2.0), copied verbatim in the file "LICENSE".              *
*                                                                             *
* In applying this licence, CERN does not waive the privileges and immunities *
* granted to it by virtue of its status as an Intergovernmental Organization  *
* or submit itself to any jurisdiction.                                       *
\*****************************************************************************/

#include "DownstreamConsolidate.cuh"

/**
 * @file DownstreamConsolidate.cu
 * @brief This file contains the implementation of the downstream consolidation
 * kernels.
 * @details The downstream consolidation is done in two steps:
 * 1. The first kernel fills the consolidation memory with the data from the downstream tracks.
 * 2. The second kernel creates the views for the downstream tracks.
 */

INSTANTIATE_ALGORITHM(downstream_consolidate::downstream_consolidate_t)

__global__ void downstream_consolidate::downstream_create_tracks_view(
  downstream_consolidate::Parameters parameters,
  Allen::Monitoring::Histogram<>::DeviceType dev_histogram_downstream_track_eta,
  Allen::Monitoring::Histogram<>::DeviceType dev_histogram_downstream_track_phi,
  Allen::Monitoring::Histogram<>::DeviceType dev_histogram_downstream_track_nhits)
{
  // Basic
  const unsigned event_number = blockIdx.x;
  const unsigned number_of_events = parameters.dev_number_of_events[0];

  // Event offsets for tracks
  const auto downstream_tracks_offset = parameters.dev_offsets_downstream_tracks[event_number];
  const auto downstream_tracks_size =
    parameters.dev_offsets_downstream_tracks[event_number + 1] - downstream_tracks_offset;

  // Consolidated memories
  const auto downstream_track_scifi_indices = parameters.dev_downstream_track_scifi_idx + downstream_tracks_offset;

  //
  // Create views for downstream ut tracks
  //
  for (unsigned track_index = threadIdx.x; track_index < downstream_tracks_size; track_index += blockDim.x) {
    new (parameters.dev_downstream_ut_track_view + downstream_tracks_offset + track_index)
      Allen::Views::UT::Consolidated::Track {parameters.dev_downstream_hits_view,
                                             parameters.dev_offsets_downstream_tracks,
                                             parameters.dev_offsets_downstream_hit_numbers,
                                             track_index,
                                             event_number};
  }

  if (threadIdx.x == 0) {
    new (parameters.dev_downstream_hits_view + event_number)
      Allen::Views::UT::Consolidated::Hits {parameters.dev_downstream_track_hits,
                                            parameters.dev_offsets_downstream_tracks,
                                            parameters.dev_offsets_downstream_hit_numbers,
                                            event_number,
                                            number_of_events};

    new (parameters.dev_downstream_ut_tracks_view + event_number) Allen::Views::UT::Consolidated::Tracks {
      parameters.dev_downstream_ut_track_view, parameters.dev_offsets_downstream_tracks, event_number};
  }

  if (blockIdx.x == 0 && threadIdx.x == 0) {
    new (parameters.dev_multi_event_downstream_ut_tracks_view)
      Allen::Views::UT::Consolidated::MultiEventTracks {parameters.dev_downstream_ut_tracks_view, number_of_events};
    parameters.dev_multi_event_downstream_ut_tracks_view_ptr[0] = parameters.dev_multi_event_downstream_ut_tracks_view;
  }

  //
  // Create views for kalman states
  //
  if (threadIdx.x == 0) {
    new (parameters.dev_downstream_track_states_view + event_number) Allen::Views::Physics::KalmanStates {
      parameters.dev_downstream_track_states, parameters.dev_offsets_downstream_tracks, event_number, number_of_events};
  }

  //
  // Create views for downstream tracks
  //
  for (unsigned track_index = threadIdx.x; track_index < downstream_tracks_size; track_index += blockDim.x) {
    const auto scifi_track_index = downstream_track_scifi_indices[track_index];
    const auto downstream_track_index = downstream_tracks_offset + track_index;
    new (parameters.dev_downstream_track_view + downstream_track_index) Allen::Views::Physics::DownstreamTrack {
      parameters.dev_downstream_ut_track_view + downstream_track_index,
      &parameters.dev_scifi_tracks_view[event_number].track(scifi_track_index),
      parameters.dev_downstream_track_qops + downstream_track_index,
      parameters.dev_downstream_track_ghost_probability + downstream_track_index};
  }

  if (threadIdx.x == 0) {
    new (parameters.dev_downstream_tracks_view + event_number) Allen::Views::Physics::DownstreamTracks {
      parameters.dev_downstream_track_view, parameters.dev_offsets_downstream_tracks, event_number};
  }

  if (blockIdx.x == 0 && threadIdx.x == 0) {
    new (parameters.dev_multi_event_downstream_tracks_view)
      Allen::Views::Physics::MultiEventDownstreamTracks {parameters.dev_downstream_tracks_view, number_of_events};
    parameters.dev_multi_event_downstream_tracks_view_ptr[0] = parameters.dev_multi_event_downstream_tracks_view;
  }

  __syncthreads();

  //
  // Fill monitoring
  //
  for (unsigned track_index = threadIdx.x; track_index < downstream_tracks_size; track_index += blockDim.x) {
    const auto downstream_track_index = downstream_tracks_offset + track_index;
    downstream_consolidate::downstream_consolidate_t::monitor(
      parameters.dev_downstream_track_view[downstream_track_index],
      parameters.dev_downstream_track_states_view[event_number].state(track_index),
      dev_histogram_downstream_track_eta,
      dev_histogram_downstream_track_phi,
      dev_histogram_downstream_track_nhits);
  }
}

void downstream_consolidate::downstream_consolidate_t::set_arguments_size(
  ArgumentReferences<Parameters> arguments,
  const RuntimeOptions&,
  const Constants&) const
{
  // Consolidated objects
  set_size<dev_downstream_track_states_t>(
    arguments, first<host_number_of_downstream_tracks_t>(arguments) * Velo::Consolidated::States::size);
  set_size<dev_downstream_track_hits_t>(
    arguments, first<host_number_of_hits_in_downstream_tracks_t>(arguments) * UT::Consolidated::Hits::element_size);
  set_size<dev_downstream_track_qops_t>(arguments, first<host_number_of_downstream_tracks_t>(arguments));
  set_size<dev_downstream_track_ghost_probability_t>(arguments, first<host_number_of_downstream_tracks_t>(arguments));
  set_size<dev_downstream_track_scifi_idx_t>(arguments, first<host_number_of_downstream_tracks_t>(arguments));
  set_size<dev_downstream_track_scifi_states_t>(arguments, first<host_number_of_downstream_tracks_t>(arguments));

  // UT track views
  set_size<dev_downstream_hits_view_t>(arguments, first<host_number_of_events_t>(arguments));
  set_size<dev_downstream_ut_track_view_t>(arguments, first<host_number_of_downstream_tracks_t>(arguments));
  set_size<dev_downstream_ut_tracks_view_t>(arguments, first<host_number_of_events_t>(arguments));
  set_size<dev_multi_event_downstream_ut_tracks_view_t>(arguments, 1u);
  set_size<dev_multi_event_downstream_ut_tracks_view_ptr_t>(arguments, 1u);

  // Kalman states
  set_size<dev_downstream_track_states_view_t>(arguments, first<host_number_of_events_t>(arguments));
  // Downstream track views
  set_size<dev_downstream_track_view_t>(arguments, first<host_number_of_downstream_tracks_t>(arguments));
  set_size<dev_downstream_tracks_view_t>(arguments, first<host_number_of_events_t>(arguments));
  set_size<dev_multi_event_downstream_tracks_view_t>(arguments, 1u);
  set_size<dev_multi_event_downstream_tracks_view_ptr_t>(arguments, 1u);
}

void downstream_consolidate::downstream_consolidate_t::operator()(
  const ArgumentReferences<Parameters>& arguments,
  const RuntimeOptions&,
  const Constants&,
  const Allen::Context& context) const
{
  // Initialize container to avoid invalid std::function destructor
  Allen::memset_async<dev_downstream_track_states_t>(arguments, 0, context);
  Allen::memset_async<dev_downstream_track_hits_t>(arguments, 0, context);
  Allen::memset_async<dev_downstream_hits_view_t>(arguments, 0, context);
  Allen::memset_async<dev_downstream_ut_track_view_t>(arguments, 0, context);
  Allen::memset_async<dev_downstream_ut_tracks_view_t>(arguments, 0, context);
  Allen::memset_async<dev_multi_event_downstream_ut_tracks_view_t>(arguments, 0, context);
  Allen::memset_async<dev_multi_event_downstream_ut_tracks_view_ptr_t>(arguments, 0, context);
  Allen::memset_async<dev_downstream_track_states_view_t>(arguments, 0, context);
  Allen::memset_async<dev_downstream_track_view_t>(arguments, 0, context);
  Allen::memset_async<dev_downstream_tracks_view_t>(arguments, 0, context);
  Allen::memset_async<dev_multi_event_downstream_tracks_view_t>(arguments, 0, context);
  Allen::memset_async<dev_multi_event_downstream_tracks_view_ptr_t>(arguments, 0, context);

  // Fill the consolidation memory
  global_function(downstream_consolidate)(dim3(size<dev_event_list_t>(arguments)), m_block_dim, context)(
    arguments, m_histogram_n_downstream_tracks.data(context), m_downstream_tracks.data(context));

  // Create views
  global_function(downstream_create_tracks_view)(dim3(first<host_number_of_events_t>(arguments)), 256, context)(
    arguments,
    m_histogram_downstream_track_eta.data(context),
    m_histogram_downstream_track_phi.data(context),
    m_histogram_downstream_track_nhits.data(context));
}

__global__ void downstream_consolidate::downstream_consolidate(
  downstream_consolidate::Parameters parameters,
  // Monitoring
  Allen::Monitoring::Histogram<>::DeviceType dev_histogram_n_downstream_tracks,
  Allen::Monitoring::AveragingCounter<>::DeviceType dev_n_downstream_tracks_counter)
{
  // Basic
  const unsigned event_number = parameters.dev_event_list[blockIdx.x];
  const unsigned number_of_events = parameters.dev_number_of_events[0];

  // Tracks
  auto downstream_tracks = parameters.dev_downstream_tracks + event_number * UT::Constants::max_num_tracks;
  const auto downstream_tracks_offset = parameters.dev_offsets_downstream_tracks[event_number];
  const auto downstream_tracks_size =
    parameters.dev_offsets_downstream_tracks[event_number + 1] - downstream_tracks_offset;

  // Event offsets for hit ofsets
  const auto downstream_hit_number_offsets = parameters.dev_offsets_downstream_hit_numbers + downstream_tracks_offset;

  // SciFi offsets
  const auto scifi_tracks_offset = parameters.dev_scifi_tracks_view[event_number].offset();

  // Total numbers
  const auto downstream_total_number_of_tracks = parameters.dev_offsets_downstream_tracks[number_of_events];
  const auto downstream_total_number_of_hits =
    parameters.dev_offsets_downstream_hit_numbers[downstream_total_number_of_tracks];

  // Input UT hits
  const unsigned total_number_of_hits = parameters.dev_ut_hit_offsets[number_of_events * UT::Constants::n_groups];
  const UT::HitOffsets ut_hit_offsets {parameters.dev_ut_hit_offsets, event_number};
  const auto event_hit_offset = ut_hit_offsets.event_offset();
  UT::ConstHits ut_hits {parameters.dev_ut_hits, total_number_of_hits, event_hit_offset};

  // Monitoring fill
  if (threadIdx.x == 0) {
    dev_histogram_n_downstream_tracks.increment(downstream_tracks_size);
    dev_n_downstream_tracks_counter.add(downstream_tracks_size);
  }

  // Outputs
  const auto downstream_track_scifi_indices = parameters.dev_downstream_track_scifi_idx + downstream_tracks_offset;
  const auto downstream_track_qops = parameters.dev_downstream_track_qops + downstream_tracks_offset;
  const auto downstream_track_ghost_probability =
    parameters.dev_downstream_track_ghost_probability + downstream_tracks_offset;
  const auto downstream_track_scifi_states = parameters.dev_downstream_track_scifi_states + downstream_tracks_offset;

  UT::Consolidated::Hits downstream_track_hits(
    parameters.dev_downstream_track_hits, 0, downstream_total_number_of_hits);

  UT::Consolidated::Tracks output_tracks(
    parameters.dev_offsets_downstream_tracks,
    parameters.dev_offsets_downstream_hit_numbers,
    event_number,
    number_of_events);

  Velo::Consolidated::States output_states(
    parameters.dev_downstream_track_states, downstream_total_number_of_tracks, downstream_tracks_offset);

  // Fill start
  for (unsigned track_idx = threadIdx.x; track_idx < downstream_tracks_size; track_idx += blockDim.x) {
    const auto& downstream_track = downstream_tracks[track_idx];

    // Fill states
    output_states.x(track_idx) = downstream_track.x;
    output_states.y(track_idx) = downstream_track.y;
    output_states.tx(track_idx) = downstream_track.tx;
    output_states.ty(track_idx) = downstream_track.ty;
    output_states.qop(track_idx) = downstream_track.qop;
    output_states.chi2(track_idx) = downstream_track.chi2;
    output_states.ndof(track_idx) = 1;

    // Fill consolidation info
    downstream_track_scifi_indices[track_idx] = downstream_track.scifi_idx;
    downstream_track_qops[track_idx] = downstream_track.qop;
    downstream_track_ghost_probability[track_idx] = downstream_track.ghost_prob;
    downstream_track_scifi_states[track_idx] =
      parameters.dev_scifi_states[scifi_tracks_offset + downstream_track.scifi_idx];

    // Fill hits
    const auto target_hit_offset = downstream_hit_number_offsets[track_idx];
    constexpr auto INVALID_HIT = Downstream::DownstreamStructs::DownstreamHits::INVALID_HIT;
    for (unsigned layer = 0, hit_idx = 0; layer < UT::Constants::n_layers; layer++) {
      const auto ut_hit_idx = downstream_track.hits[hit_idx];
      if (ut_hit_idx == INVALID_HIT) continue;
      downstream_track_hits.yBegin(target_hit_offset + hit_idx) = ut_hits.yBegin(ut_hit_idx);
      downstream_track_hits.yEnd(target_hit_offset + hit_idx) = ut_hits.yEnd(ut_hit_idx);
      downstream_track_hits.zAtYEq0(target_hit_offset + hit_idx) = ut_hits.zAtYEq0(ut_hit_idx);
      downstream_track_hits.xAtYEq0(target_hit_offset + hit_idx) = ut_hits.xAtYEq0(ut_hit_idx);
      downstream_track_hits.dxDy(target_hit_offset + hit_idx) = ut_hits.dxDy(ut_hit_idx);
      downstream_track_hits.weight(target_hit_offset + hit_idx) = ut_hits.weight(ut_hit_idx);
      downstream_track_hits.id(target_hit_offset + hit_idx) = ut_hits.id(ut_hit_idx);
      downstream_track_hits.plane_code(target_hit_offset + hit_idx) = layer;
      hit_idx++;
    }
  }
  __syncthreads();
}

__device__ void downstream_consolidate::downstream_consolidate_t::monitor(
  const Allen::Views::Physics::DownstreamTrack downstream_track,
  const Allen::Views::Physics::KalmanState downstream_state,
  Allen::Monitoring::Histogram<>::DeviceType& dev_histogram_downstream_track_eta,
  Allen::Monitoring::Histogram<>::DeviceType& dev_histogram_downstream_track_phi,
  Allen::Monitoring::Histogram<>::DeviceType& dev_histogram_downstream_track_nhits)
{
  const auto nhits = downstream_track.number_of_hits();
  const auto tx = downstream_state.tx();
  const auto ty = downstream_state.ty();
  const auto slope2 = tx * tx + ty * ty;
  const auto rho = std::sqrt(slope2);
  const auto eta = eta_from_rho(rho);
  const auto phi = std::atan2(ty, tx);

  dev_histogram_downstream_track_eta.increment(eta);
  dev_histogram_downstream_track_phi.increment(phi);
  dev_histogram_downstream_track_nhits.increment(nhits);
}
