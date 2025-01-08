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
#include "DownstreamExtrapolation.cuh"
#include "DownstreamHelper.cuh"

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
  set_size<dev_downstream_particles_ip_t>(arguments, first<host_number_of_downstream_tracks_t>(arguments));
  set_size<dev_downstream_particles_pv_t>(arguments, first<host_number_of_downstream_tracks_t>(arguments));
  set_size<dev_downstream_track_particle_view_t>(arguments, first<host_number_of_downstream_tracks_t>(arguments));
  set_size<dev_downstream_track_particles_view_t>(arguments, first<host_number_of_events_t>(arguments));
  set_size<dev_multi_event_downstream_track_particles_view_t>(arguments, 1);
  set_size<dev_multi_event_downstream_track_particles_view_ptr_t>(arguments, 1);
}

void downstream_make_particles::downstream_make_particles_t::operator()(
  const ArgumentReferences<Parameters>& arguments,
  const RuntimeOptions&,
  const Constants& constants,
  const Allen::Context& context) const
{
  // Initialize container to avoid invalid std::function destructor
  Allen::memset_async<dev_downstream_track_particles_view_t>(arguments, 0, context);
  Allen::memset_async<dev_multi_event_downstream_track_particles_view_t>(arguments, 0, context);
  Allen::memset_async<dev_downstream_particles_ip_t>(arguments, 0, context);
  Allen::memset_async<dev_downstream_particles_pv_t>(arguments, 0, context);

  global_function(downstream_make_particles)(dim3(size<dev_event_list_t>(arguments)), m_block_dim, context)(
    arguments, constants.dev_magnet_polarity.data());

  global_function(downstream_create_particles_views)(dim3(first<host_number_of_events_t>(arguments)), 128, context)(
    arguments,
    m_histogram_n_trks.data(context),
    m_histogram_trk_eta.data(context),
    m_histogram_trk_phi.data(context),
    m_histogram_trk_pt.data(context));
}

__global__ void downstream_make_particles::downstream_create_particles_views(
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

  // Create particles
  for (unsigned track_index = threadIdx.x; track_index < event_downstream_tracks_size; track_index += blockDim.x) {
    const auto& downstream_track = downstream_tracks.track(track_index);
    const auto best_pv_ptr = parameters.dev_downstream_particles_pv[event_downstream_tracks_offset + track_index];

    // Create particle
    new (parameters.dev_downstream_track_particle_view + event_downstream_tracks_offset + track_index)
      Allen::Views::Physics::BasicParticle {&downstream_track,
                                            parameters.dev_downstream_track_states_view + event_number,
                                            best_pv_ptr,
                                            track_index,
                                            parameters.dev_lepton_id[event_downstream_tracks_offset + track_index],
                                            parameters.dev_downstream_particles_ip + event_downstream_tracks_offset +
                                              track_index};
  }

  // Create particles
  if (threadIdx.x == 0) {
    new (parameters.dev_downstream_track_particles_view + event_number) Allen::Views::Physics::BasicParticles {
      parameters.dev_downstream_track_particle_view, parameters.dev_offsets_downstream_tracks, event_number};
  }

  // Multi event containers
  if (blockIdx.x == 0 && threadIdx.x == 0) {
    new (parameters.dev_multi_event_downstream_track_particles_view) Allen::Views::Physics::MultiEventBasicParticles {
      parameters.dev_downstream_track_particles_view, number_of_events};
    parameters.dev_multi_event_downstream_track_particles_view_ptr[0] =
      parameters.dev_multi_event_downstream_track_particles_view;
  }

  __syncthreads();

  //
  // Fill Monitoring
  //
  if (threadIdx.x == 0) dev_histogram_n_trks.increment(event_downstream_tracks_size);

  for (unsigned track_index = threadIdx.x; track_index < event_downstream_tracks_size; track_index += blockDim.x) {
    auto state = parameters.dev_downstream_track_states_view[event_number].state(track_index);
    dev_histogram_trk_eta.increment(state.eta());
    dev_histogram_trk_phi.increment(std::atan2(state.ty(), state.tx()));
    dev_histogram_trk_pt.increment(state.pt());
  };
}

__global__ void downstream_make_particles::downstream_make_particles(
  downstream_make_particles::Parameters parameters,
  const float* dev_magnet_polarity)
{
  // Basic
  const unsigned event_number = parameters.dev_event_list[blockIdx.x];
  // const unsigned number_of_events = parameters.dev_number_of_events[0];

  // Get tracks
  const auto downstream_tracks = parameters.dev_multi_event_downstream_tracks_view->container(event_number);

  // Get offsets
  const unsigned event_downstream_tracks_offset = downstream_tracks.offset();
  const unsigned event_downstream_tracks_size = downstream_tracks.size();

  // Get pvs
  const auto pvs = parameters.dev_multi_final_vertices + event_number * PV::max_number_vertices;
  const auto num_pvs = parameters.dev_number_of_multi_final_vertices[event_number];

  // Create particles
  for (unsigned track_index = threadIdx.x; track_index < event_downstream_tracks_size; track_index += blockDim.x) {
    // const auto& downstream_track = downstream_tracks.track(track_index);

    // Fetch state
    auto state = parameters.dev_downstream_track_states_view[event_number].state(track_index);

    // Obtain paramters for downstream trajectory
    const auto gA = Downstream::DownstreamExtrapolation::Physics::gamma(state.qop(), *dev_magnet_polarity);

    // Find best PV
    Downstream::DownstreamHelpers::BestCandidateManager<unsigned> best_pv;
    for (unsigned pv_idx = 0; pv_idx < num_pvs; pv_idx++) {
      const auto pv = pvs[pv_idx].position;
      const auto& pvx = pv.x;
      const auto& pvy = pv.y;
      const auto& pvz = pv.z;

      const auto& z0 = state.z();
      const auto& xA = state.x();
      const auto& txA = state.tx();
      const auto& yA = state.y();
      const auto& tyA = state.ty();

      const auto min_z0 = -(-pvz - pvx * txA - pvy * tyA + txA * xA + tyA * yA + z0) / (1.f + txA * txA + tyA * tyA);

      const auto a = -pvz - pvx * txA - pvy * tyA + txA * xA + tyA * yA + z0;
      const auto b = 1.f - 2.f * gA * pvx + txA * txA + tyA * tyA + 2 * gA * xA;
      const auto c = 3.f * gA * txA;
      const auto d = 2 * gA * gA;

      auto f = [a, b, c, d](const float x) { return a + b * x + c * x * x + d * x * x * x; };
      auto fp = [b, c, d](const float x) { return b + 2 * c * x + 3 * d * x * x; };

      const auto min_z = Downstream::DownstreamHelpers::find_root<4>(f, fp, min_z0);

      const auto dx = xA + txA * min_z + gA * min_z * min_z - pvx;
      const auto dy = yA + tyA * min_z - pvz;
      const auto dz = min_z + z0 - pvz;

      const auto d2 = dx * dx + dy * dy + dz * dz;

      best_pv.add(pv_idx, d2);
    }

    const auto best_pv_ptr = best_pv.exist() ? pvs + best_pv.best() : nullptr;
    const auto best_ip = best_pv.exist() ? best_pv.score() : std::numeric_limits<float>::quiet_NaN();

    // Fill ip
    parameters.dev_downstream_particles_pv[event_downstream_tracks_offset + track_index] = best_pv_ptr;
    parameters.dev_downstream_particles_ip[event_downstream_tracks_offset + track_index] = best_ip;
  };
}