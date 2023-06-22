/*****************************************************************************\
* (c) Copyright 2018-2020 CERN for the benefit of the LHCb Collaboration      *
\*****************************************************************************/
#include "ConsolidateMatchedTracks.cuh"

INSTANTIATE_ALGORITHM(matching_consolidate_tracks::matching_consolidate_tracks_t);

__global__ void create_matched_views(matching_consolidate_tracks::Parameters parameters)
{
  const unsigned number_of_events = parameters.dev_number_of_events[0];
  const unsigned event_number = blockIdx.x;

  const auto event_tracks_offset = parameters.dev_atomics_matched[event_number];
  const auto event_number_of_tracks = parameters.dev_atomics_matched[event_number + 1] - event_tracks_offset;
  for (unsigned track_index = threadIdx.x; track_index < event_number_of_tracks; track_index += blockDim.x) {
    const auto velo_track_index = parameters.dev_matched_track_velo_indices + event_tracks_offset + track_index;
    const auto scifi_track_index = parameters.dev_matched_track_scifi_indices + event_tracks_offset + track_index;
    const auto* velo_track = &parameters.dev_velo_tracks_view[event_number].track(*velo_track_index);
    const auto* scifi_track = &parameters.dev_scifi_tracks_view[event_number].track(*scifi_track_index);

    // Mark velo tracks as used
    parameters.dev_accepted_and_unused_velo_tracks[velo_track->track_container_offset() + velo_track->track_index()] =
      0;

    new (parameters.dev_long_track_view + event_tracks_offset + track_index) Allen::Views::Physics::LongTrack {
      velo_track, nullptr, scifi_track, parameters.dev_matched_qop + event_tracks_offset + track_index};
  }
  if (threadIdx.x == 0) {
    new (parameters.dev_long_tracks_view + event_number)
      Allen::Views::Physics::LongTracks {parameters.dev_long_track_view, parameters.dev_atomics_matched, event_number};
  }
  if (blockIdx.x == 0 && threadIdx.x == 0) {
    new (parameters.dev_multi_event_long_tracks_view)
      Allen::Views::Physics::MultiEventLongTracks {parameters.dev_long_tracks_view, number_of_events};
    parameters.dev_multi_event_long_tracks_ptr[0] = parameters.dev_multi_event_long_tracks_view.data();
  }
}

void matching_consolidate_tracks::matching_consolidate_tracks_t::set_arguments_size(
  ArgumentReferences<Parameters> arguments,
  const RuntimeOptions&,
  const Constants&) const
{
  set_size<dev_matched_track_hits_t>(
    arguments, first<host_accumulated_number_of_hits_in_matched_tracks_t>(arguments) * sizeof(SciFi::Hit));
  set_size<dev_matched_qop_t>(arguments, first<host_number_of_reconstructed_matched_tracks_t>(arguments));
  set_size<dev_scifi_states_t>(arguments, first<host_number_of_reconstructed_matched_tracks_t>(arguments));
  set_size<dev_matched_track_velo_indices_t>(
    arguments, first<host_number_of_reconstructed_matched_tracks_t>(arguments));
  set_size<dev_matched_track_scifi_indices_t>(
    arguments, first<host_number_of_reconstructed_matched_tracks_t>(arguments));
  set_size<dev_long_track_view_t>(arguments, first<host_number_of_reconstructed_matched_tracks_t>(arguments));
  set_size<dev_long_tracks_view_t>(arguments, first<host_number_of_events_t>(arguments));
  set_size<dev_multi_event_long_tracks_view_t>(arguments, 1);
  set_size<dev_multi_event_long_tracks_ptr_t>(arguments, 1);
  set_size<dev_accepted_and_unused_velo_tracks_t>(arguments, size<dev_accepted_velo_tracks_t>(arguments));
}

void matching_consolidate_tracks::matching_consolidate_tracks_t::init()
{
#ifndef ALLEN_STANDALONE
  m_long_tracks_matching = new Gaudi::Accumulators::Counter<>(this, "n_long_tracks_matching");
  histogram_n_long_tracks_matching = new gaudi_monitoring::Lockable_Histogram<> {
    {this, "n_long_tracks_matching_event", "n_long_tracks_matching_event", {80, 0, 200}}, {}};
  histogram_long_track_matching_eta =
    new gaudi_monitoring::Lockable_Histogram<> {{this,
                                                 "long_track_matching_eta",
                                                 "#eta",
                                                 {property<histogram_long_track_matching_eta_nbins_t>(),
                                                  property<histogram_long_track_matching_eta_min_t>(),
                                                  property<histogram_long_track_matching_eta_max_t>()}},
                                                {}};
  histogram_long_track_matching_phi =
    new gaudi_monitoring::Lockable_Histogram<> {{this,
                                                 "long_track_matching_phi",
                                                 "#phi",
                                                 {property<histogram_long_track_matching_phi_nbins_t>(),
                                                  property<histogram_long_track_matching_phi_min_t>(),
                                                  property<histogram_long_track_matching_phi_max_t>()}},
                                                {}};
  histogram_long_track_matching_nhits =
    new gaudi_monitoring::Lockable_Histogram<> {{this,
                                                 "long_track_matching_nhits",
                                                 "N. hits / track",
                                                 {property<histogram_long_track_matching_nhits_nbins_t>(),
                                                  property<histogram_long_track_matching_nhits_min_t>(),
                                                  property<histogram_long_track_matching_nhits_max_t>()}},
                                                {}};
#endif
}

void matching_consolidate_tracks::matching_consolidate_tracks_t::operator()(
  const ArgumentReferences<Parameters>& arguments,
  const RuntimeOptions&,
  const Constants&,
  const Allen::Context& context) const
{
  Allen::copy_async<dev_accepted_and_unused_velo_tracks_t, dev_accepted_velo_tracks_t>(arguments, context);

  auto dev_histogram_long_track_matching_eta =
    make_device_buffer<unsigned>(arguments, property<histogram_long_track_matching_eta_nbins_t>());
  auto dev_histogram_long_track_matching_phi =
    make_device_buffer<unsigned>(arguments, property<histogram_long_track_matching_phi_nbins_t>());
  auto dev_histogram_long_track_matching_nhits =
    make_device_buffer<unsigned>(arguments, property<histogram_long_track_matching_nhits_nbins_t>());
  auto dev_histogram_n_long_tracks_matching = make_device_buffer<unsigned>(arguments, 80u);
  auto dev_n_long_tracks_matching_counter = make_device_buffer<unsigned>(arguments, 1u);
  Allen::memset_async(
    dev_histogram_long_track_matching_eta.data(),
    0,
    dev_histogram_long_track_matching_eta.size() * sizeof(unsigned),
    context);
  Allen::memset_async(
    dev_histogram_long_track_matching_phi.data(),
    0,
    dev_histogram_long_track_matching_phi.size() * sizeof(unsigned),
    context);
  Allen::memset_async(
    dev_histogram_long_track_matching_nhits.data(),
    0,
    dev_histogram_long_track_matching_nhits.size() * sizeof(unsigned),
    context);
  Allen::memset_async(
    dev_histogram_n_long_tracks_matching.data(),
    0,
    dev_histogram_n_long_tracks_matching.size() * sizeof(unsigned),
    context);
  Allen::memset_async(
    dev_n_long_tracks_matching_counter.data(),
    0,
    dev_n_long_tracks_matching_counter.size() * sizeof(unsigned),
    context);

  global_function(matching_consolidate_tracks)(
    dim3(size<dev_event_list_t>(arguments)), property<block_dim_t>(), context)(
    arguments,
    dev_histogram_long_track_matching_eta.get(),
    dev_histogram_long_track_matching_phi.get(),
    dev_histogram_long_track_matching_nhits.get(),
    dev_histogram_n_long_tracks_matching.get(),
    dev_n_long_tracks_matching_counter.get());

  global_function(create_matched_views)(first<host_number_of_events_t>(arguments), 256, context)(arguments);

#ifndef ALLEN_STANDALONE
  // Monitoring
  gaudi_monitoring::fill(
    arguments,
    context,
    std::tuple {std::tuple {dev_histogram_long_track_matching_eta.get(),
                            histogram_long_track_matching_eta,
                            property<histogram_long_track_matching_eta_min_t>(),
                            property<histogram_long_track_matching_eta_max_t>()},
                std::tuple {dev_histogram_long_track_matching_phi.get(),
                            histogram_long_track_matching_phi,
                            property<histogram_long_track_matching_phi_min_t>(),
                            property<histogram_long_track_matching_phi_max_t>()},
                std::tuple {dev_histogram_long_track_matching_nhits.get(),
                            histogram_long_track_matching_nhits,
                            property<histogram_long_track_matching_nhits_min_t>(),
                            property<histogram_long_track_matching_nhits_max_t>()},
                std::tuple {dev_histogram_n_long_tracks_matching.get(), histogram_n_long_tracks_matching, 0, 200},
                std::tuple {dev_n_long_tracks_matching_counter.get(), m_long_tracks_matching}});
#endif
}

__global__ void matching_consolidate_tracks::matching_consolidate_tracks(
  matching_consolidate_tracks::Parameters parameters,
  gsl::span<unsigned> dev_histogram_long_track_matching_eta,
  gsl::span<unsigned> dev_histogram_long_track_matching_phi,
  gsl::span<unsigned> dev_histogram_long_track_matching_nhits,
  gsl::span<unsigned> dev_histogram_n_long_tracks_matching,
  gsl::span<unsigned> dev_n_long_tracks_matching_counter)
{
  const unsigned event_number = parameters.dev_event_list[blockIdx.x];

  const SciFi::MatchedTrack* event_matched_tracks =
    parameters.dev_matched_tracks + event_number * TrackMatchingConsts::max_num_tracks;

  // SciFi seed views
  const auto scifi_seeds = parameters.dev_scifi_tracks_view[event_number];

  const unsigned event_scifi_seeds_offset = scifi_seeds.offset();
  const auto* seeding_states = parameters.dev_seeding_states + event_scifi_seeds_offset;

  // output SciFi states for matched long tracks
  MiniState* scifi_states = parameters.dev_scifi_states + parameters.dev_atomics_matched[event_number];

  float* tracks_qop = parameters.dev_matched_qop + parameters.dev_atomics_matched[event_number];
  unsigned int* tracks_velo_indices =
    parameters.dev_matched_track_velo_indices + parameters.dev_atomics_matched[event_number];
  unsigned int* tracks_scifi_indices =
    parameters.dev_matched_track_scifi_indices + parameters.dev_atomics_matched[event_number];
  const unsigned number_of_tracks_event =
    parameters.dev_atomics_matched[event_number + 1] - parameters.dev_atomics_matched[event_number];

  for (unsigned i = threadIdx.x; i < number_of_tracks_event; i += blockDim.x) {
    const SciFi::MatchedTrack& track = event_matched_tracks[i];
    tracks_qop[i] = track.qop;
    tracks_velo_indices[i] = track.velo_track_index;
    tracks_scifi_indices[i] = track.scifi_track_index;
    scifi_states[i] = seeding_states[track.scifi_track_index];
#ifndef ALLEN_STANDALONE
    const auto velo_track = parameters.dev_velo_tracks_view[event_number].track(track.velo_track_index);
    const auto velo_state = parameters.dev_velo_states_view[event_number].state(track.velo_track_index);
    matching_consolidate_tracks::matching_consolidate_tracks_t::monitor(
      parameters,
      track,
      velo_track,
      velo_state,
      dev_histogram_long_track_matching_eta,
      dev_histogram_long_track_matching_phi,
      dev_histogram_long_track_matching_nhits);

    if (number_of_tracks_event < 200) {
      unsigned bin = std::floor(number_of_tracks_event / 2.5);
      dev_histogram_n_long_tracks_matching[bin]++;
    }
    dev_n_long_tracks_matching_counter[0] += number_of_tracks_event;
#endif
  }
}

__device__ void matching_consolidate_tracks::matching_consolidate_tracks_t::monitor(
  const matching_consolidate_tracks::Parameters& parameters,
  const SciFi::MatchedTrack matched_track,
  const Allen::Views::Velo::Consolidated::Track,
  const Allen::Views::Physics::KalmanState velo_state,
  gsl::span<unsigned> dev_histogram_long_track_matching_eta,
  gsl::span<unsigned> dev_histogram_long_track_matching_phi,
  gsl::span<unsigned> dev_histogram_long_track_matching_nhits)
{

  const auto tx = velo_state.tx();
  const auto ty = velo_state.ty();
  const float slope2 = tx * tx + ty * ty;
  const float rho = std::sqrt(slope2);
  const unsigned nhits = matched_track.number_of_hits_velo + matched_track.number_of_hits_scifi;
  const auto eta = eta_from_rho(rho);
  const auto phi = std::atan2(ty, tx);
  // printf("tx %.4f , ty %.4f, nhits: %d \n", tx,ty,nhits);

  if (
    eta > parameters.histogram_long_track_matching_eta_min && eta < parameters.histogram_long_track_matching_eta_max) {
    const unsigned int bin = static_cast<unsigned int>(
      (eta - parameters.histogram_long_track_matching_eta_min) * parameters.histogram_long_track_matching_eta_nbins /
      (parameters.histogram_long_track_matching_eta_max - parameters.histogram_long_track_matching_eta_min));
    ++dev_histogram_long_track_matching_eta[bin];
  }
  if (
    phi > parameters.histogram_long_track_matching_phi_min && phi < parameters.histogram_long_track_matching_phi_max) {
    const unsigned int bin = static_cast<unsigned int>(
      (phi - parameters.histogram_long_track_matching_phi_min) * parameters.histogram_long_track_matching_phi_nbins /
      (parameters.histogram_long_track_matching_phi_max - parameters.histogram_long_track_matching_phi_min));
    ++dev_histogram_long_track_matching_phi[bin];
  }
  if (
    nhits > parameters.histogram_long_track_matching_nhits_min &&
    nhits < parameters.histogram_long_track_matching_nhits_max) {
    const unsigned int bin = static_cast<unsigned int>(
      (nhits - parameters.histogram_long_track_matching_nhits_min) *
      parameters.histogram_long_track_matching_nhits_nbins /
      (parameters.histogram_long_track_matching_nhits_max - parameters.histogram_long_track_matching_nhits_min));
    ++dev_histogram_long_track_matching_nhits[bin];
  }
}
