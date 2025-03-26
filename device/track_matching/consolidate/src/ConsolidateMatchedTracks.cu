/*****************************************************************************\
* (c) Copyright 2018-2020 CERN for the benefit of the LHCb Collaboration      *
*                                                                             *
* This software is distributed under the terms of the Apache License          *
* version 2 (Apache-2.0), copied verbatim in the file "LICENSE".              *
*                                                                             *
* In applying this licence, CERN does not waive the privileges and immunities *
* granted to it by virtue of its status as an Intergovernmental Organization  *
* or submit itself to any jurisdiction.                                       *
\*****************************************************************************/
#include "ConsolidateMatchedTracks.cuh"
#include "PrefixSum.cuh"

INSTANTIATE_ALGORITHM(matching_consolidate_tracks::matching_consolidate_tracks_t);

void matching_consolidate_tracks::matching_consolidate_tracks_t::set_arguments_size(
  ArgumentReferences<Parameters> arguments,
  const RuntimeOptions&,
  const Constants&) const
{
  // Working memory (Temporal)
  set_size<dev_matched_track_velo_indices_t>(
    arguments, first<host_number_of_reconstructed_matched_tracks_t>(arguments));
  set_size<dev_matched_track_scifi_indices_t>(
    arguments, first<host_number_of_reconstructed_matched_tracks_t>(arguments));

  // Outputs (VeloScifi/General part)
  set_size<dev_matched_qop_t>(arguments, first<host_number_of_reconstructed_matched_tracks_t>(arguments));
  set_size<dev_matched_ghost_probability_t>(arguments, first<host_number_of_reconstructed_matched_tracks_t>(arguments));
  set_size<dev_scifi_states_t>(arguments, first<host_number_of_reconstructed_matched_tracks_t>(arguments));
  set_size<dev_accepted_and_unused_velo_tracks_t>(arguments, size<dev_accepted_velo_tracks_t>(arguments));
  set_size<dev_matched_is_scifi_track_used_t>(arguments, first<host_number_of_reconstructed_scifi_tracks_t>(arguments));

  // Long tracks views
  set_size<dev_long_track_view_t>(arguments, first<host_number_of_reconstructed_matched_tracks_t>(arguments));
  set_size<dev_long_tracks_view_t>(arguments, first<host_number_of_events_t>(arguments));
  set_size<dev_multi_event_long_tracks_view_t>(arguments, 1);
  set_size<dev_multi_event_long_tracks_ptr_t>(arguments, 1);

  //
  // UT
  //
  if (size<dev_ut_hits_t>(arguments) > 0) {
    // Outputs (UT part)
    set_size<dev_matched_ut_track_hits_t>(
      arguments,
      first<host_accumulated_number_of_ut_hits_in_matched_tracks_t>(arguments) * UT::Consolidated::Hits::element_size);

    // UT tracks views
    set_size<dev_matched_ut_track_hits_view_t>(arguments, first<host_number_of_events_t>(arguments));
    set_size<dev_matched_ut_track_view_t>(arguments, first<host_number_of_reconstructed_matched_tracks_t>(arguments));

    // Filter used ut hits
    set_size<dev_used_ut_hits_offsets_t>(arguments, first<host_accumulated_number_of_ut_hits_t>(arguments) + 1);
  }
  else {
    // In no ut case we don't use any memory for ut info
    set_size<dev_matched_ut_track_hits_t>(arguments, 0);
    set_size<dev_matched_ut_track_hits_view_t>(arguments, 0);
    set_size<dev_matched_ut_track_view_t>(arguments, 0);
  }
}

void matching_consolidate_tracks::matching_consolidate_tracks_t::operator()(
  const ArgumentReferences<Parameters>& arguments,
  const RuntimeOptions&,
  [[maybe_unused]] const Constants& constants,
  const Allen::Context& context) const
{
  const auto has_ut =
    (size<dev_ut_hits_t>(arguments) > 0) && (first<host_accumulated_number_of_ut_hits_t>(arguments) > 0);
  if (size<dev_used_ut_hits_offsets_t>(arguments) > 0) {
    Allen::memset_async<dev_used_ut_hits_offsets_t>(arguments, 0, context);
  }

  // Reset masks
  Allen::memset_async<dev_matched_is_scifi_track_used_t>(arguments, 0, context);
  Allen::copy_async<dev_accepted_and_unused_velo_tracks_t, dev_accepted_velo_tracks_t>(arguments, context);

  if (has_ut) {
    global_function(matching_consolidate_tracks<true>)(dim3(size<dev_event_list_t>(arguments)), m_block_dim, context)(
      arguments,
      m_histogram_long_track_matching_eta.data(context),
      m_histogram_long_track_matching_phi.data(context),
      m_histogram_long_track_matching_nhits.data(context),
      m_histogram_long_track_ghost_prob.data(context),
      m_histogram_n_long_tracks_matching.data(context),
      m_histogram_long_track_matching_qop.data(context),
      m_long_tracks_matching.data(context));

    global_function(matching_create_longtracks_views<true>)(first<host_number_of_events_t>(arguments), 256, context)(
      arguments);

    PrefixSum::prefix_sum<dev_used_ut_hits_offsets_t>(*this, arguments, context);
  }
  else {
    global_function(matching_consolidate_tracks<false>)(dim3(size<dev_event_list_t>(arguments)), m_block_dim, context)(
      arguments,
      m_histogram_long_track_matching_eta.data(context),
      m_histogram_long_track_matching_phi.data(context),
      m_histogram_long_track_matching_nhits.data(context),
      m_histogram_long_track_ghost_prob.data(context),
      m_histogram_n_long_tracks_matching.data(context),
      m_histogram_long_track_matching_qop.data(context),
      m_long_tracks_matching.data(context));
    global_function(matching_create_longtracks_views<false>)(first<host_number_of_events_t>(arguments), 256, context)(
      arguments);
  }
}

template<bool has_ut>
__global__ void matching_consolidate_tracks::matching_create_longtracks_views(
  matching_consolidate_tracks::Parameters parameters)
{
  // Basic
  const unsigned event_number = blockIdx.x;
  const unsigned number_of_events = parameters.dev_number_of_events[0];

  // Track offsets
  const auto tracks_offset = parameters.dev_offsets_matched_tracks[event_number];
  const auto number_of_tracks = parameters.dev_offsets_matched_tracks[event_number + 1] - tracks_offset;

  if constexpr (has_ut) {
    // Create views
    if (threadIdx.x == 0) {
      new (parameters.dev_matched_ut_track_hits_view + event_number)
        Allen::Views::UT::Consolidated::Hits {parameters.dev_matched_ut_track_hits,
                                              parameters.dev_offsets_matched_tracks,
                                              parameters.dev_offsets_matched_ut_hit_number,
                                              event_number,
                                              number_of_events};
    }

    for (unsigned track_index = threadIdx.x; track_index < number_of_tracks; track_index += blockDim.x) {
      new (parameters.dev_matched_ut_track_view + tracks_offset + track_index)
        Allen::Views::UT::Consolidated::Track {parameters.dev_matched_ut_track_hits_view,
                                               parameters.dev_offsets_matched_tracks,
                                               parameters.dev_offsets_matched_ut_hit_number,
                                               track_index,
                                               event_number};
    }
  }

  for (unsigned track_index = threadIdx.x; track_index < number_of_tracks; track_index += blockDim.x) {
    const auto velo_track_index = parameters.dev_matched_track_velo_indices + tracks_offset + track_index;
    const auto scifi_track_index = parameters.dev_matched_track_scifi_indices + tracks_offset + track_index;
    const auto* velo_track = &parameters.dev_velo_tracks_view[event_number].track(*velo_track_index);
    const auto* scifi_track = &parameters.dev_scifi_tracks_view[event_number].track(*scifi_track_index);

    // Mark scifi track as used
    parameters.dev_matched_is_scifi_track_used[scifi_track->track_container_offset() + scifi_track->track_index()] =
      true;

    // Mark velo tracks as used
    parameters.dev_accepted_and_unused_velo_tracks[velo_track->track_container_offset() + velo_track->track_index()] =
      0;

    if constexpr (has_ut) {
      new (parameters.dev_long_track_view + tracks_offset + track_index)
        Allen::Views::Physics::LongTrack {velo_track,
                                          parameters.dev_matched_ut_track_view + tracks_offset + track_index,
                                          scifi_track,
                                          nullptr,
                                          parameters.dev_matched_qop + tracks_offset + track_index,
                                          parameters.dev_matched_ghost_probability + tracks_offset + track_index};
    }
    else {
      new (parameters.dev_long_track_view + tracks_offset + track_index)
        Allen::Views::Physics::LongTrack {velo_track,
                                          nullptr,
                                          scifi_track,
                                          nullptr,
                                          parameters.dev_matched_qop + tracks_offset + track_index,
                                          parameters.dev_matched_ghost_probability + tracks_offset + track_index};
    }
  }

  if (threadIdx.x == 0) {
    new (parameters.dev_long_tracks_view + event_number) Allen::Views::Physics::LongTracks {
      parameters.dev_long_track_view, parameters.dev_offsets_matched_tracks, event_number};
  }

  if (blockIdx.x == 0 && threadIdx.x == 0) {
    new (parameters.dev_multi_event_long_tracks_view)
      Allen::Views::Physics::MultiEventLongTracks {parameters.dev_long_tracks_view, number_of_events};
    parameters.dev_multi_event_long_tracks_ptr[0] = parameters.dev_multi_event_long_tracks_view.data();
  }
}

template<bool has_ut>
__global__ void matching_consolidate_tracks::matching_consolidate_tracks(
  matching_consolidate_tracks::Parameters parameters,
  [[maybe_unused]] Allen::Monitoring::Histogram<>::DeviceType dev_histogram_long_track_matching_eta,
  [[maybe_unused]] Allen::Monitoring::Histogram<>::DeviceType dev_histogram_long_track_matching_phi,
  [[maybe_unused]] Allen::Monitoring::Histogram<>::DeviceType dev_histogram_long_track_matching_nhits,
  [[maybe_unused]] Allen::Monitoring::Histogram<>::DeviceType dev_histogram_long_track_ghost_prob,
  [[maybe_unused]] Allen::Monitoring::Histogram<>::DeviceType dev_histogram_n_long_tracks_matching,
  [[maybe_unused]] Allen::Monitoring::Histogram<>::DeviceType dev_histogram_long_track_matching_qop,
  [[maybe_unused]] Allen::Monitoring::AveragingCounter<>::DeviceType dev_n_long_tracks_matching_counter)
{
  const unsigned event_number = parameters.dev_event_list[blockIdx.x];

  const SciFi::MatchedTrack* event_matched_tracks =
    parameters.dev_matched_tracks + event_number * TrackMatchingConsts::max_num_tracks;

  // SciFi seed views
  const auto scifi_seeds = parameters.dev_scifi_tracks_view[event_number];

  const unsigned event_scifi_seeds_offset = scifi_seeds.offset();
  const auto* seeding_states = parameters.dev_seeding_states + event_scifi_seeds_offset;

  // output SciFi states for matched long tracks
  const auto matched_tracks_offset = parameters.dev_offsets_matched_tracks[event_number];

  MiniState* scifi_states = parameters.dev_scifi_states + matched_tracks_offset;

  float* tracks_qop = parameters.dev_matched_qop + matched_tracks_offset;
  float* tracks_ghsot_probability = parameters.dev_matched_ghost_probability + matched_tracks_offset;
  unsigned int* tracks_velo_indices = parameters.dev_matched_track_velo_indices + matched_tracks_offset;
  unsigned int* tracks_scifi_indices = parameters.dev_matched_track_scifi_indices + matched_tracks_offset;
  const unsigned number_of_tracks_event =
    parameters.dev_offsets_matched_tracks[event_number + 1] - matched_tracks_offset;

  //
  // Fill UT hits
  //
  if constexpr (has_ut) {
    // Basics
    const unsigned number_of_events = parameters.dev_number_of_events[0];

    // Input UT hits
    const unsigned total_number_of_ut_hits = parameters.dev_ut_hit_offsets[number_of_events * UT::Constants::n_groups];
    const UT::HitOffsets ut_hit_offsets {parameters.dev_ut_hit_offsets, event_number};
    const auto event_hit_offset = ut_hit_offsets.event_offset();
    UT::ConstHits ut_hits {parameters.dev_ut_hits, total_number_of_ut_hits, event_hit_offset};

    // Output UT hits
    const auto total_number_matched_tracks = parameters.dev_offsets_matched_tracks[number_of_events];
    const auto total_number_matched_ut_hit = parameters.dev_offsets_matched_ut_hit_number[total_number_matched_tracks];
    UT::Consolidated::Hits matched_ut_track_hits(parameters.dev_matched_ut_track_hits, 0, total_number_matched_ut_hit);

    for (unsigned i = threadIdx.x; i < number_of_tracks_event; i += blockDim.x) {
      const auto& matched_track = event_matched_tracks[i];
      const auto hit_offset = parameters.dev_offsets_matched_ut_hit_number[matched_tracks_offset + i];
      for (unsigned layer = 0, hit_idx = 0; layer < UT::Constants::n_layers; layer++) {
        const auto ut_hit_idx = matched_track.ut_hits[layer];
        if (ut_hit_idx == SciFi::MatchedTrack::InvalidHit) continue;
        matched_ut_track_hits.yBegin(hit_offset + hit_idx) = ut_hits.yBegin(ut_hit_idx);
        matched_ut_track_hits.yEnd(hit_offset + hit_idx) = ut_hits.yEnd(ut_hit_idx);
        matched_ut_track_hits.zAtYEq0(hit_offset + hit_idx) = ut_hits.zAtYEq0(ut_hit_idx);
        matched_ut_track_hits.xAtYEq0(hit_offset + hit_idx) = ut_hits.xAtYEq0(ut_hit_idx);
        matched_ut_track_hits.dxDy(hit_offset + hit_idx) = ut_hits.dxDy(ut_hit_idx);
        matched_ut_track_hits.weight(hit_offset + hit_idx) = ut_hits.weight(ut_hit_idx);
        matched_ut_track_hits.id(hit_offset + hit_idx) = ut_hits.id(ut_hit_idx);
        matched_ut_track_hits.original_index(hit_offset + hit_idx) = ut_hit_idx + event_hit_offset;
        matched_ut_track_hits.plane_code(hit_offset + hit_idx) = layer;
        parameters.dev_used_ut_hits_offsets[event_hit_offset + ut_hit_idx] = 1;
        hit_idx++;
      }
    }
  }

  //
  // Fill tracks info
  //
  for (unsigned i = threadIdx.x; i < number_of_tracks_event; i += blockDim.x) {
    const SciFi::MatchedTrack& track = event_matched_tracks[i];
    tracks_qop[i] = track.qop;
    tracks_ghsot_probability[i] = track.score;
    tracks_velo_indices[i] = track.velo_track_index;
    tracks_scifi_indices[i] = track.scifi_track_index;
    scifi_states[i] = seeding_states[track.scifi_track_index];
  }

//
// Monitoring
//
#ifndef ALLEN_STANDALONE
  for (unsigned i = threadIdx.x; i < number_of_tracks_event; i += blockDim.x) {
    const SciFi::MatchedTrack& track = event_matched_tracks[i];
    const auto scifi_track = parameters.dev_scifi_tracks_view[event_number].track(track.scifi_track_index);
    const auto velo_track = parameters.dev_velo_tracks_view[event_number].track(track.velo_track_index);
    const auto velo_state = parameters.dev_velo_states_view[event_number].state(track.velo_track_index);
    matching_consolidate_tracks::matching_consolidate_tracks_t::monitor(
      track,
      scifi_track,
      velo_track,
      velo_state,
      dev_histogram_long_track_matching_eta,
      dev_histogram_long_track_matching_phi,
      dev_histogram_long_track_matching_qop,
      dev_histogram_long_track_matching_nhits,
      dev_histogram_long_track_ghost_prob);
  }

  if (threadIdx.x == 0) {
    dev_histogram_n_long_tracks_matching.increment(number_of_tracks_event);
    dev_n_long_tracks_matching_counter.add(number_of_tracks_event);
  }

#endif
}

__device__ void matching_consolidate_tracks::matching_consolidate_tracks_t::monitor(
  const SciFi::MatchedTrack matched_track,
  const Allen::Views::SciFi::Consolidated::Track scifi_track,
  const Allen::Views::Velo::Consolidated::Track velo_track,
  const Allen::Views::Physics::KalmanState velo_state,
  Allen::Monitoring::Histogram<>::DeviceType& dev_histogram_long_track_matching_eta,
  Allen::Monitoring::Histogram<>::DeviceType& dev_histogram_long_track_matching_phi,
  Allen::Monitoring::Histogram<>::DeviceType& dev_histogram_long_track_matching_qop,
  Allen::Monitoring::Histogram<>::DeviceType& dev_histogram_long_track_matching_nhits,
  Allen::Monitoring::Histogram<>::DeviceType& dev_histogram_long_track_ghost_prob)
{
  const auto tx = velo_state.tx();
  const auto ty = velo_state.ty();
  const float slope2 = tx * tx + ty * ty;
  const float rho = std::sqrt(slope2);
  const unsigned nhits =
    velo_track.number_of_hits() + matched_track.number_of_hits_ut + scifi_track.number_of_scifi_hits();
  const auto eta = eta_from_rho(rho);
  const auto phi = std::atan2(ty, tx);

  dev_histogram_long_track_matching_eta.increment(eta);
  dev_histogram_long_track_matching_phi.increment(phi);
  dev_histogram_long_track_matching_nhits.increment(nhits);
  dev_histogram_long_track_matching_qop.increment(matched_track.qop);
  dev_histogram_long_track_ghost_prob.increment(matched_track.score);
}
