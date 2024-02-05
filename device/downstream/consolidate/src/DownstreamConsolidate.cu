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
  // Monitoring
  gsl::span<unsigned> dev_histogram_downstream_track_eta,
  gsl::span<unsigned> dev_histogram_downstream_track_phi,
  gsl::span<unsigned> dev_histogram_downstream_track_nhits)
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
    new (parameters.dev_downstream_track_view + downstream_track_index)
      Allen::Views::Physics::DownstreamTrack {&parameters.dev_downstream_ut_track_view[downstream_track_index],
                                              &parameters.dev_scifi_tracks_view[event_number].track(scifi_track_index),
                                              &parameters.dev_downstream_track_qops[downstream_track_index]};
    //
    // Fill monitoring
    //
    downstream_consolidate::downstream_consolidate_t::monitor(
      parameters,
      parameters.dev_downstream_track_view[downstream_track_index],
      parameters.dev_downstream_track_states_view[event_number].state(track_index),
      dev_histogram_downstream_track_eta,
      dev_histogram_downstream_track_phi,
      dev_histogram_downstream_track_nhits);
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
  set_size<dev_downstream_track_scifi_idx_t>(arguments, first<host_number_of_downstream_tracks_t>(arguments));

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

void downstream_consolidate::downstream_consolidate_t::init()
{
#ifndef ALLEN_STANDALONE
  m_downstream_tracks = new Gaudi::Accumulators::Counter<>(this, "n_downstream_tracks");
  histogram_n_downstream_tracks = new gaudi_monitoring::Lockable_Histogram<> {
    {this, "n_downstream_tracks_event", "n_downstream_tracks_event", {80, 0, 200}}, {}};
  histogram_downstream_track_eta =
    new gaudi_monitoring::Lockable_Histogram<> {{this,
                                                 "downstream_track_eta",
                                                 "#eta",
                                                 {property<histogram_downstream_track_eta_nbins_t>(),
                                                  property<histogram_downstream_track_eta_min_t>(),
                                                  property<histogram_downstream_track_eta_max_t>()}},
                                                {}};
  histogram_downstream_track_phi =
    new gaudi_monitoring::Lockable_Histogram<> {{this,
                                                 "downstream_track_phi",
                                                 "#phi",
                                                 {property<histogram_downstream_track_phi_nbins_t>(),
                                                  property<histogram_downstream_track_phi_min_t>(),
                                                  property<histogram_downstream_track_phi_max_t>()}},
                                                {}};
  histogram_downstream_track_nhits =
    new gaudi_monitoring::Lockable_Histogram<> {{this,
                                                 "downstream_track_nhits",
                                                 "N. hits / track",
                                                 {property<histogram_downstream_track_nhits_nbins_t>(),
                                                  property<histogram_downstream_track_nhits_min_t>(),
                                                  property<histogram_downstream_track_nhits_max_t>()}},
                                                {}};
#endif
}

void downstream_consolidate::downstream_consolidate_t::operator()(
  const ArgumentReferences<Parameters>& arguments,
  const RuntimeOptions&,
  const Constants& constants,
  const Allen::Context& context) const
{
  // Initialize container to avoid invalid std::function destructor
  Allen::memset_async<dev_multi_event_downstream_tracks_view_t>(arguments, 0, context);
  Allen::memset_async<dev_downstream_tracks_view_t>(arguments, 0, context);

  //
  // Create monitoring container
  //
  auto dev_histogram_downstream_track_eta =
    make_device_buffer<unsigned>(arguments, property<histogram_downstream_track_eta_nbins_t>());
  auto dev_histogram_downstream_track_phi =
    make_device_buffer<unsigned>(arguments, property<histogram_downstream_track_phi_nbins_t>());
  auto dev_histogram_downstream_track_nhits =
    make_device_buffer<unsigned>(arguments, property<histogram_downstream_track_nhits_nbins_t>());
  auto dev_histogram_n_downstream_tracks = make_device_buffer<unsigned>(arguments, 80u);
  auto dev_n_downstream_tracks_counter = make_device_buffer<unsigned>(arguments, 1u);

  //
  // Initialize monitoring container
  //
  Allen::memset_async(
    dev_histogram_downstream_track_eta.data(),
    0,
    dev_histogram_downstream_track_eta.size() * sizeof(unsigned),
    context);
  Allen::memset_async(
    dev_histogram_downstream_track_phi.data(),
    0,
    dev_histogram_downstream_track_phi.size() * sizeof(unsigned),
    context);
  Allen::memset_async(
    dev_histogram_downstream_track_nhits.data(),
    0,
    dev_histogram_downstream_track_nhits.size() * sizeof(unsigned),
    context);
  Allen::memset_async(
    dev_histogram_n_downstream_tracks.data(), 0, dev_histogram_n_downstream_tracks.size() * sizeof(unsigned), context);
  Allen::memset_async(
    dev_n_downstream_tracks_counter.data(), 0, dev_n_downstream_tracks_counter.size() * sizeof(unsigned), context);

  // Fill the consolidation memory
  global_function(downstream_consolidate)(dim3(size<dev_event_list_t>(arguments)), property<block_dim_t>(), context)(
    arguments,
    constants.dev_unique_x_sector_layer_offsets.data(),
    dev_histogram_n_downstream_tracks.get(),
    dev_n_downstream_tracks_counter.get());

  // Create views
  global_function(downstream_create_tracks_view)(dim3(first<host_number_of_events_t>(arguments)), 256, context)(
    arguments,
    dev_histogram_downstream_track_eta.get(),
    dev_histogram_downstream_track_phi.get(),
    dev_histogram_downstream_track_nhits.get());

#ifndef ALLEN_STANDALONE
  gaudi_monitoring::fill(
    arguments,
    context,
    std::tuple {std::tuple {dev_histogram_downstream_track_eta.get(),
                            histogram_downstream_track_eta,
                            property<histogram_downstream_track_eta_min_t>(),
                            property<histogram_downstream_track_eta_max_t>()},
                std::tuple {dev_histogram_downstream_track_phi.get(),
                            histogram_downstream_track_phi,
                            property<histogram_downstream_track_phi_min_t>(),
                            property<histogram_downstream_track_phi_max_t>()},
                std::tuple {dev_histogram_downstream_track_nhits.get(),
                            histogram_downstream_track_nhits,
                            property<histogram_downstream_track_nhits_min_t>(),
                            property<histogram_downstream_track_nhits_max_t>()},
                std::tuple {dev_histogram_n_downstream_tracks.get(), histogram_n_downstream_tracks, 0, 200},
                std::tuple {dev_n_downstream_tracks_counter.get(), m_downstream_tracks}});
#endif
}

__global__ void downstream_consolidate::downstream_consolidate(
  downstream_consolidate::Parameters parameters,
  const unsigned* dev_unique_x_sector_layer_offsets,
  // Monitoring
  gsl::span<unsigned> dev_histogram_n_downstream_tracks,
  gsl::span<unsigned> dev_n_downstream_tracks_counter)
{
  // Basic
  const unsigned event_number = parameters.dev_event_list[blockIdx.x];
  const unsigned number_of_events = parameters.dev_number_of_events[0];

  // Tracks
  const auto downstream_tracks_memory =
    parameters.dev_downstream_tracks + event_number * UT::DownstreamTracks::TotalMemorySize;
  UT::DownstreamTracks_Const downstream_tracks {downstream_tracks_memory};

  // Event offsets for tracks
  const auto downstream_tracks_offset = parameters.dev_offsets_downstream_tracks[event_number];
  const auto downstream_tracks_size =
    parameters.dev_offsets_downstream_tracks[event_number + 1] - downstream_tracks_offset;

  // Event offsets for hit ofsets
  const auto downstream_hit_number_offsets = parameters.dev_offsets_downstream_hit_numbers + downstream_tracks_offset;

  // Total numbers
  const auto downstream_total_number_of_tracks = parameters.dev_offsets_downstream_tracks[number_of_events];
  const auto downstream_total_number_of_hits =
    parameters.dev_offsets_downstream_hit_numbers[downstream_total_number_of_tracks];

  // UT hits
  const unsigned number_of_unique_x_sectors = dev_unique_x_sector_layer_offsets[UT::Constants::n_layers];
  const unsigned total_number_of_hits = parameters.dev_ut_hit_offsets[number_of_events * number_of_unique_x_sectors];
  const UT::HitOffsets ut_hit_offsets {
    parameters.dev_ut_hit_offsets, event_number, number_of_unique_x_sectors, dev_unique_x_sector_layer_offsets};
  const auto event_hit_offset = ut_hit_offsets.event_offset();
  UT::ConstHits ut_hits {parameters.dev_ut_hits, total_number_of_hits, event_hit_offset};

  //
  // Monitoring fill
  //
  if (downstream_tracks_size < 200) {
    unsigned bin = std::floor(downstream_tracks_size / 2.5);
    dev_histogram_n_downstream_tracks[bin]++;
  }
  dev_n_downstream_tracks_counter[0] += downstream_tracks_size;

  // Outputs
  const auto downstream_track_scifi_indices = parameters.dev_downstream_track_scifi_idx + downstream_tracks_offset;
  const auto downstream_track_qops = parameters.dev_downstream_track_qops + downstream_tracks_offset;

  UT::Consolidated::Hits downstream_track_hits(
    parameters.dev_downstream_track_hits, 0, downstream_total_number_of_hits);

  UT::Consolidated::Tracks output_tracks(
    parameters.dev_offsets_downstream_tracks,
    parameters.dev_offsets_downstream_hit_numbers,
    event_number,
    number_of_events);

  Velo::Consolidated::States output_states(
    parameters.dev_downstream_track_states, downstream_total_number_of_tracks, downstream_tracks_offset);

  // Fill states
  for (unsigned track_idx = threadIdx.x; track_idx < downstream_tracks_size; track_idx += blockDim.x) {

    // First AOS part of state
    output_states.x(track_idx) = downstream_tracks.x(track_idx);
    output_states.y(track_idx) = downstream_tracks.y(track_idx);
    output_states.z(track_idx) = UT::Constants::zMidUT;
    output_states.tx(track_idx) = downstream_tracks.tx(track_idx);
    output_states.ty(track_idx) = downstream_tracks.ty(track_idx);
    output_states.qop(track_idx) = downstream_tracks.qop(track_idx);

    // Fill extra qop for downstream track
    downstream_track_qops[track_idx] = downstream_tracks.qop(track_idx);

    // Second AOS part of state
    output_states.c00(track_idx) = 0.f;
    output_states.c20(track_idx) = 0.f;
    output_states.c22(track_idx) = 0.f;
    output_states.c11(track_idx) = 0.f;
    output_states.c31(track_idx) = 0.f;
    output_states.c33(track_idx) = 0.f;
    output_states.chi2(track_idx) = downstream_tracks.chi2(track_idx);
    output_states.ndof(track_idx) = downstream_tracks.n_hits(track_idx) - 1u;
  }

  // Scifi idx
  for (unsigned track_idx = threadIdx.x; track_idx < downstream_tracks_size; track_idx += blockDim.x) {
    downstream_track_scifi_indices[track_idx] = downstream_tracks.scifi(track_idx);
  }

  // Fill hits
  for (unsigned track_idx = threadIdx.x; track_idx < downstream_tracks_size; track_idx += blockDim.x) {
    const auto nhits = downstream_tracks.n_hits(track_idx);
    const auto target_hit_offset = downstream_hit_number_offsets[track_idx];
    for (unsigned hit_idx = 0; hit_idx < nhits; hit_idx++) {
      downstream_track_hits.set(
        target_hit_offset + hit_idx, ut_hits.getHit(downstream_tracks.hits(track_idx, hit_idx)));
    }
  }

  __syncthreads();
}

__device__ void downstream_consolidate::downstream_consolidate_t::monitor(
  const downstream_consolidate::Parameters& parameters,
  const Allen::Views::Physics::DownstreamTrack downstream_track,
  const Allen::Views::Physics::KalmanState downstream_state,
  gsl::span<unsigned> dev_histogram_downstream_track_eta,
  gsl::span<unsigned> dev_histogram_downstream_track_phi,
  gsl::span<unsigned> dev_histogram_downstream_track_nhits)
{
  const auto nhits = downstream_track.number_of_hits();
  const auto tx = downstream_state.tx();
  const auto ty = downstream_state.ty();
  const auto slope2 = tx * tx + ty * ty;
  const auto rho = std::sqrt(slope2);
  const auto eta = eta_from_rho(rho);
  const auto phi = std::atan2(ty, tx);

  // Filling histograms
  if (eta > parameters.histogram_downstream_track_eta_min && eta < parameters.histogram_downstream_track_eta_max) {
    const unsigned int bin = static_cast<unsigned int>(
      (eta - parameters.histogram_downstream_track_eta_min) * parameters.histogram_downstream_track_eta_nbins /
      (parameters.histogram_downstream_track_eta_max - parameters.histogram_downstream_track_eta_min));
    ++dev_histogram_downstream_track_eta[bin];
  }
  if (phi > parameters.histogram_downstream_track_phi_min && phi < parameters.histogram_downstream_track_phi_max) {
    const unsigned int bin = static_cast<unsigned int>(
      (phi - parameters.histogram_downstream_track_phi_min) * parameters.histogram_downstream_track_phi_nbins /
      (parameters.histogram_downstream_track_phi_max - parameters.histogram_downstream_track_phi_min));
    ++dev_histogram_downstream_track_phi[bin];
  }
  if (
    nhits > parameters.histogram_downstream_track_nhits_min &&
    nhits < parameters.histogram_downstream_track_nhits_max) {
    const unsigned int bin = static_cast<unsigned int>(
      (nhits - parameters.histogram_downstream_track_nhits_min) * parameters.histogram_downstream_track_nhits_nbins /
      (parameters.histogram_downstream_track_nhits_max - parameters.histogram_downstream_track_nhits_min));
    ++dev_histogram_downstream_track_nhits[bin];
  }
}
