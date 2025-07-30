/*****************************************************************************\
* (c) Copyright 2022 CERN for the benefit of the LHCb Collaboration           *
*                                                                             *
* This software is distributed under the terms of the Apache License          *
* version 2 (Apache-2.0), copied verbatim in the file "COPYING".              *
*                                                                             *
* In applying this licence, CERN does not waive the privileges and immunities *
* granted to it by virtue of its status as an Intergovernmental Organization  *
* or submit itself to any jurisdiction.                                       *
\*****************************************************************************/
#include "MakeLongTrackParticles.cuh"
#include "ArgumentOps.cuh"

INSTANTIATE_ALGORITHM(make_long_track_particles::make_long_track_particles_t)

void make_long_track_particles::make_long_track_particles_t::set_arguments_size(
  ArgumentReferences<Parameters> arguments,
  const RuntimeOptions&,
  const Constants&) const
{
  auto n_scifi_tracks = first<host_number_of_reconstructed_scifi_tracks_t>(arguments);
  set_size<dev_long_track_particle_view_t>(arguments, n_scifi_tracks);
  set_size<dev_long_track_particles_view_t>(arguments, first<host_number_of_events_t>(arguments));
  set_size<dev_multi_event_basic_particles_view_t>(arguments, 1);
  set_size<dev_multi_event_container_basic_particles_t>(arguments, 1);
}

void make_long_track_particles::make_long_track_particles_t::operator()(
  const ArgumentReferences<Parameters>& arguments,
  const RuntimeOptions&,
  const Constants&,
  const Allen::Context& context) const
{
  Allen::memset_async<dev_long_track_particle_view_t>(arguments, 0, context);

  global_function(make_particles)(dim3(first<host_number_of_events_t>(arguments)), m_block_dim, context)(
    arguments,
    size<dev_event_list_t>(arguments),
    m_histogram_n_trks.data(context),
    m_histogram_trk_eta.data(context),
    m_histogram_trk_phi.data(context),
    m_histogram_trk_pt.data(context));
}

void __global__ make_long_track_particles::make_particles(
  make_long_track_particles::Parameters parameters,
  unsigned event_list_size,
  Allen::Monitoring::Histogram<>::DeviceType dev_histogram_n_trks,
  Allen::Monitoring::Histogram<>::DeviceType dev_histogram_trk_eta,
  Allen::Monitoring::Histogram<>::DeviceType dev_histogram_trk_phi,
  Allen::Monitoring::Histogram<>::DeviceType dev_histogram_trk_pt)
{
  const unsigned number_of_events = parameters.dev_number_of_events[0];
  const unsigned event_index = blockIdx.x;

  if (event_index < event_list_size) {
    const unsigned event_number = parameters.dev_event_list[event_index];
    const auto* mec =
      static_cast<const Allen::Views::Physics::MultiEventLongTracks*>(parameters.dev_multi_event_long_tracks[0]);
    const auto event_long_tracks = mec->container(event_number);
    const unsigned offset = event_long_tracks.offset();
    const unsigned number_of_tracks = event_long_tracks.size();
    const auto pv_table = parameters.dev_kalman_pv_tables[event_number];

    if (threadIdx.x == 0) {
      dev_histogram_n_trks.increment(number_of_tracks);
    }

    for (unsigned i = threadIdx.x; i < number_of_tracks; i += blockDim.x) {
      const auto* long_track = &(event_long_tracks.track(i));
      const int i_pv = pv_table.pv(i);
      new (parameters.dev_long_track_particle_view + offset + i) Allen::Views::Physics::BasicParticle {
        long_track,
        parameters.dev_kalman_states_view + event_number,
        i_pv >= 0 ? parameters.dev_multi_final_vertices + PV::max_number_vertices * event_number + pv_table.pv(i) :
                    nullptr,
        i,
        parameters.dev_lepton_id[offset + i]};

      auto state = (parameters.dev_kalman_states_view + event_number)->state(i);
      dev_histogram_trk_eta.increment(state.eta());
      dev_histogram_trk_phi.increment(std::atan2(state.ty(), state.tx()));
      dev_histogram_trk_pt.increment(state.pt());
    }
  }

  if (threadIdx.x == 0) {
    new (parameters.dev_long_track_particles_view + event_index) Allen::Views::Physics::BasicParticles {
      parameters.dev_long_track_particle_view, parameters.dev_atomics_scifi, event_index};
  }

  if (blockIdx.x == 0 && threadIdx.x == 0) {
    new (parameters.dev_multi_event_basic_particles_view)
      Allen::Views::Physics::MultiEventBasicParticles {parameters.dev_long_track_particles_view, number_of_events};
    parameters.dev_multi_event_container_basic_particles[0] = parameters.dev_multi_event_basic_particles_view;
  }
}
