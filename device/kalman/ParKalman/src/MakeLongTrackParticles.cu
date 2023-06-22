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

void make_long_track_particles::make_long_track_particles_t::init()
{
#ifndef ALLEN_STANDALONE
  histogram_n_trks = new gaudi_monitoring::Lockable_Histogram<> {
    {this, "number_of_trks", "NTrks", {UT::Constants::max_num_tracks, 0, UT::Constants::max_num_tracks}}, {}};
  histogram_trk_eta = new gaudi_monitoring::Lockable_Histogram<> {{this, "trk_eta", "etaTrk", {100, 0, 5}}, {}};
  histogram_trk_phi = new gaudi_monitoring::Lockable_Histogram<> {{this, "trk_phi", "phiTrk", {100, -3.2, 3.2}}, {}};
  histogram_trk_pt =
    new gaudi_monitoring::Lockable_Histogram<> {{this, "trk_pt", "ptTrk", {100, 0, (unsigned) 1e4}}, {}};
#endif
}

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
  auto dev_histogram_n_trks = make_device_buffer<unsigned>(arguments, UT::Constants::max_num_tracks);
  auto dev_histogram_trk_eta = make_device_buffer<unsigned>(arguments, 100u);
  auto dev_histogram_trk_phi = make_device_buffer<unsigned>(arguments, 100u);
  auto dev_histogram_trk_pt = make_device_buffer<unsigned>(arguments, 100u);
  Allen::memset_async(dev_histogram_n_trks.data(), 0, dev_histogram_n_trks.size() * sizeof(unsigned), context);
  Allen::memset_async(dev_histogram_trk_eta.data(), 0, dev_histogram_trk_eta.size() * sizeof(unsigned), context);
  Allen::memset_async(dev_histogram_trk_phi.data(), 0, dev_histogram_trk_phi.size() * sizeof(unsigned), context);
  Allen::memset_async(dev_histogram_trk_pt.data(), 0, dev_histogram_trk_pt.size() * sizeof(unsigned), context);
  Allen::memset_async<dev_long_track_particle_view_t>(arguments, 0, context);

  global_function(make_particles)(dim3(first<host_number_of_events_t>(arguments)), property<block_dim_t>(), context)(
    arguments,
    dev_histogram_n_trks.get(),
    dev_histogram_trk_eta.get(),
    dev_histogram_trk_phi.get(),
    dev_histogram_trk_pt.get());

#ifndef ALLEN_STANDALONE
  gaudi_monitoring::fill(
    arguments,
    context,
    std::tuple {std::tuple {dev_histogram_n_trks.get(), histogram_n_trks, 0, UT::Constants::max_num_tracks},
                std::tuple {dev_histogram_trk_eta.get(), histogram_trk_eta, 0, 5},
                std::tuple {dev_histogram_trk_phi.get(), histogram_trk_phi, -3.2f, 3.2f},
                std::tuple {dev_histogram_trk_pt.get(), histogram_trk_pt, 0u, unsigned(1e4)}});
#endif
}

void __global__ make_long_track_particles::make_particles(
  make_long_track_particles::Parameters parameters,
  gsl::span<unsigned> dev_histogram_n_trks,
  gsl::span<unsigned> dev_histogram_trk_eta,
  gsl::span<unsigned> dev_histogram_trk_phi,
  gsl::span<unsigned> dev_histogram_trk_pt)
{
  const unsigned number_of_events = parameters.dev_number_of_events[0];
  const unsigned event_number = blockIdx.x;
  const auto* mec =
    static_cast<const Allen::Views::Physics::MultiEventLongTracks*>(parameters.dev_multi_event_long_tracks[0]);
  const auto event_long_tracks = mec->container(event_number);
  const unsigned offset = event_long_tracks.offset();
  const unsigned number_of_tracks = event_long_tracks.size();
  const auto pv_table = parameters.dev_kalman_pv_tables[event_number];

  if (number_of_tracks < UT::Constants::max_num_tracks) ++dev_histogram_n_trks[number_of_tracks];

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
    const unsigned etabin = max(0u, min(99u, static_cast<unsigned>(state.eta() * 20)));
    ++dev_histogram_trk_eta[etabin];
    const unsigned phibin = max(0u, min(99u, static_cast<unsigned>(std::atan2(state.ty(), state.tx()) * 15.625f + 50)));
    ++dev_histogram_trk_phi[phibin];
    const unsigned ptbin = min(99u, static_cast<unsigned>(state.pt() * 0.01f));
    ++dev_histogram_trk_pt[ptbin];
  }

  if (threadIdx.x == 0) {
    new (parameters.dev_long_track_particles_view + event_number) Allen::Views::Physics::BasicParticles {
      parameters.dev_long_track_particle_view, parameters.dev_atomics_scifi, event_number};
  }

  if (blockIdx.x == 0 && threadIdx.x == 0) {
    new (parameters.dev_multi_event_basic_particles_view)
      Allen::Views::Physics::MultiEventBasicParticles {parameters.dev_long_track_particles_view, number_of_events};
    parameters.dev_multi_event_container_basic_particles[0] = parameters.dev_multi_event_basic_particles_view;
  }
}
