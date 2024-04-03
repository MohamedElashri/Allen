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

#include "DownstreamMakeParticles.cuh"

/**
 * @file DownstreamMakeParticles.cu
 * @brief This file contains the implementation of the downstream_make_particles algorithm.
 * @details This algorithm creates downstream track particles from downstream tracks.
 */

INSTANTIATE_ALGORITHM(downstream_make_particles::downstream_make_particles_t)

void downstream_make_particles::downstream_make_particles_t::set_arguments_size(
  ArgumentReferences<Parameters> arguments,
  const RuntimeOptions&,
  const Constants&) const
{
  set_size<dev_downstream_track_particle_view_t>(arguments, first<host_number_of_downstream_tracks_t>(arguments));
  set_size<dev_downstream_track_particles_view_t>(arguments, first<host_number_of_events_t>(arguments));
  set_size<dev_multi_event_downstream_track_particles_view_t>(arguments, 1);
  set_size<dev_multi_event_downstream_track_particles_view_ptr_t>(arguments, 1);
}

void downstream_make_particles::downstream_make_particles_t::operator()(
  const ArgumentReferences<Parameters>& arguments,
  const RuntimeOptions&,
  const Constants&,
  const Allen::Context& context) const
{
  // Initialize container to avoid invalid std::function destructor
  Allen::memset_async<dev_downstream_track_particles_view_t>(arguments, 0, context);
  Allen::memset_async<dev_multi_event_downstream_track_particles_view_t>(arguments, 0, context);

  global_function(downstream_make_particles)(
    dim3(first<host_number_of_events_t>(arguments)), property<block_dim_t>(), context)(
    arguments,
    m_histogram_n_trks.data(context),
    m_histogram_trk_eta.data(context),
    m_histogram_trk_phi.data(context),
    m_histogram_trk_pt.data(context));
}

__global__ void downstream_make_particles::downstream_make_particles(
  downstream_make_particles::Parameters parameters,
  Allen::Monitoring::Histogram<>::DeviceType dev_histogram_n_trks,
  Allen::Monitoring::Histogram<>::DeviceType dev_histogram_trk_eta,
  Allen::Monitoring::Histogram<>::DeviceType dev_histogram_trk_phi,
  Allen::Monitoring::Histogram<>::DeviceType dev_histogram_trk_pt)
{

  // Basic
  const unsigned event_number = blockIdx.x;
  const unsigned number_of_events = parameters.dev_number_of_events[0];

  // Get tracks
  const auto downstream_tracks = parameters.dev_multi_event_downstream_tracks_view->container(event_number);

  // Get offsets
  const unsigned event_downstream_tracks_offset = downstream_tracks.offset();
  const unsigned event_downstream_tracks_size = downstream_tracks.size();

  if (threadIdx.x == 0) dev_histogram_n_trks.increment(event_downstream_tracks_size);

  // Create particles
  for (unsigned track_index = threadIdx.x; track_index < event_downstream_tracks_size; track_index += blockDim.x) {
    const auto& downstream_track = downstream_tracks.track(track_index);
    new (parameters.dev_downstream_track_particle_view + event_downstream_tracks_offset + track_index)
      Allen::Views::Physics::BasicParticle {
        &downstream_track,
        parameters.dev_downstream_track_states_view + event_number,
        nullptr,
        track_index,
        0 // TODO: Add downstream PID in the future.
      };

    auto state = parameters.dev_downstream_track_states_view[event_number].state(track_index);
    dev_histogram_trk_eta.increment(state.eta());
    dev_histogram_trk_phi.increment(std::atan2(state.ty(), state.tx()));
    dev_histogram_trk_pt.increment(state.pt());
  };

  if (threadIdx.x == 0) {
    new (parameters.dev_downstream_track_particles_view + event_number) Allen::Views::Physics::BasicParticles {
      parameters.dev_downstream_track_particle_view, parameters.dev_offsets_downstream_tracks, event_number};
  }

  if (blockIdx.x == 0 && threadIdx.x == 0) {
    new (parameters.dev_multi_event_downstream_track_particles_view) Allen::Views::Physics::MultiEventBasicParticles {
      parameters.dev_downstream_track_particles_view, number_of_events};
    parameters.dev_multi_event_downstream_track_particles_view_ptr[0] =
      parameters.dev_multi_event_downstream_track_particles_view;
  }
}