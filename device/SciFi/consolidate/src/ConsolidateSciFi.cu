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
#include "ConsolidateSciFi.cuh"
#include "LFMomentumEstimation.cuh"
#include <PrefixSum.cuh>

INSTANTIATE_ALGORITHM(scifi_consolidate_tracks::scifi_consolidate_tracks_t)

template<bool with_ut, typename T>
__device__ void create_scifi_views_impl(
  const scifi_consolidate_tracks::Parameters& parameters,
  const T* tracks,
  Allen::Monitoring::Histogram<>::DeviceType& dev_histo_long_track_forward_eta,
  Allen::Monitoring::Histogram<>::DeviceType& dev_histo_long_track_forward_phi,
  Allen::Monitoring::Histogram<>::DeviceType& dev_histo_long_track_forward_nhits,
  Allen::Monitoring::Histogram<>::DeviceType& dev_histo_long_track_forward_qop)
{
  const unsigned number_of_events = parameters.dev_number_of_events[0];
  const unsigned event_number = blockIdx.x;

  const auto event_tracks_offset = parameters.dev_atomics_scifi[event_number];
  const auto event_number_of_tracks = parameters.dev_atomics_scifi[event_number + 1] - event_tracks_offset;
  const auto event_scifi_track_ut_indices = parameters.dev_scifi_track_ut_indices + event_tracks_offset;
  for (unsigned track_index = threadIdx.x; track_index < event_number_of_tracks; track_index += blockDim.x) {
    const auto input_track_index = event_scifi_track_ut_indices[track_index];
    const auto input_tracks_view = tracks->container(event_number);
    if constexpr (with_ut) {

      const auto* ut_track = &input_tracks_view.track(input_track_index);
      const auto* velo_track = &ut_track->velo_track();
      new (parameters.dev_scifi_track_view + event_tracks_offset + track_index)
        Allen::Views::SciFi::Consolidated::Track {parameters.dev_scifi_hits_view,
                                                  parameters.dev_scifi_qop,
                                                  parameters.dev_atomics_scifi,
                                                  parameters.dev_scifi_track_hit_number,
                                                  track_index,
                                                  event_number};
      new (parameters.dev_long_track_view + event_tracks_offset + track_index)
        Allen::Views::Physics::LongTrack {velo_track,
                                          ut_track,
                                          parameters.dev_scifi_track_view + event_tracks_offset + track_index,
                                          nullptr,
                                          parameters.dev_scifi_qop + event_tracks_offset + track_index,
                                          parameters.dev_scifi_ghost_probability + event_tracks_offset + track_index};
    }
    else {

      const auto* velo_track = &input_tracks_view.track(input_track_index);

      new (parameters.dev_scifi_track_view + event_tracks_offset + track_index)
        Allen::Views::SciFi::Consolidated::Track {parameters.dev_scifi_hits_view,
                                                  parameters.dev_scifi_qop,
                                                  parameters.dev_atomics_scifi,
                                                  parameters.dev_scifi_track_hit_number,
                                                  track_index,
                                                  event_number};
      new (parameters.dev_long_track_view + event_tracks_offset + track_index)
        Allen::Views::Physics::LongTrack {velo_track,
                                          nullptr,
                                          parameters.dev_scifi_track_view + event_tracks_offset + track_index,
                                          nullptr,
                                          parameters.dev_scifi_qop + event_tracks_offset + track_index,
                                          parameters.dev_scifi_ghost_probability + event_tracks_offset + track_index};
    }

    const auto long_track = parameters.dev_long_track_view[event_tracks_offset + track_index];
    const auto velo_state = parameters.dev_velo_states_view[event_number].state(input_track_index);
    scifi_consolidate_tracks::scifi_consolidate_tracks_t::monitor(
      long_track,
      velo_state,
      dev_histo_long_track_forward_eta,
      dev_histo_long_track_forward_phi,
      dev_histo_long_track_forward_nhits,
      dev_histo_long_track_forward_qop);
  }

  if (threadIdx.x == 0) {
    new (parameters.dev_scifi_hits_view + event_number)
      Allen::Views::SciFi::Consolidated::Hits {parameters.dev_scifi_track_hits,
                                               parameters.dev_atomics_scifi,
                                               parameters.dev_scifi_track_hit_number,
                                               event_number,
                                               number_of_events};

    new (parameters.dev_scifi_tracks_view + event_number) Allen::Views::SciFi::Consolidated::Tracks {
      parameters.dev_scifi_track_view, parameters.dev_atomics_scifi, event_number};

    new (parameters.dev_long_tracks_view + event_number)
      Allen::Views::Physics::LongTracks {parameters.dev_long_track_view, parameters.dev_atomics_scifi, event_number};
  }
  if (blockIdx.x == 0 && threadIdx.x == 0) {
    new (parameters.dev_scifi_multi_event_tracks_view)
      Allen::Views::SciFi::Consolidated::MultiEventTracks {parameters.dev_scifi_tracks_view, number_of_events};
    new (parameters.dev_multi_event_long_tracks_view)
      Allen::Views::Physics::MultiEventLongTracks {parameters.dev_long_tracks_view, number_of_events};
    parameters.dev_multi_event_long_tracks_ptr[0] = parameters.dev_multi_event_long_tracks_view.data();
  }
}

__global__ void create_scifi_views(
  scifi_consolidate_tracks::Parameters parameters,
  Allen::Monitoring::Histogram<>::DeviceType dev_histo_long_track_forward_eta,
  Allen::Monitoring::Histogram<>::DeviceType dev_histo_long_track_forward_phi,
  Allen::Monitoring::Histogram<>::DeviceType dev_histo_long_track_forward_nhits,
  Allen::Monitoring::Histogram<>::DeviceType dev_histo_long_track_forward_qop)
{
  const auto* ut_tracks =
    Allen::dyn_cast<const Allen::Views::UT::Consolidated::MultiEventVeloUTTracks*>(*parameters.dev_tracks_view);
  if (ut_tracks) {
    create_scifi_views_impl<true>(
      parameters,
      ut_tracks,
      dev_histo_long_track_forward_eta,
      dev_histo_long_track_forward_phi,
      dev_histo_long_track_forward_nhits,
      dev_histo_long_track_forward_qop);
  }
  else {
    const auto* velo_tracks =
      static_cast<const Allen::Views::Velo::Consolidated::MultiEventTracks*>(*parameters.dev_tracks_view);
    create_scifi_views_impl<false>(
      parameters,
      velo_tracks,
      dev_histo_long_track_forward_eta,
      dev_histo_long_track_forward_phi,
      dev_histo_long_track_forward_nhits,
      dev_histo_long_track_forward_qop);
  }
}

void scifi_consolidate_tracks::scifi_consolidate_tracks_t::set_arguments_size(
  ArgumentReferences<Parameters> arguments,
  const RuntimeOptions&,
  const Constants&) const
{
  set_size<dev_scifi_track_hits_t>(
    arguments, first<host_accumulated_number_of_hits_in_scifi_tracks_t>(arguments) * sizeof(SciFi::Hit));
  set_size<dev_scifi_qop_t>(arguments, first<host_number_of_reconstructed_scifi_tracks_t>(arguments));
  set_size<dev_scifi_ghost_probability_t>(arguments, first<host_number_of_reconstructed_scifi_tracks_t>(arguments));
  set_size<dev_scifi_track_ut_indices_t>(arguments, first<host_number_of_reconstructed_scifi_tracks_t>(arguments));
  set_size<dev_scifi_states_t>(arguments, first<host_number_of_reconstructed_scifi_tracks_t>(arguments));
  set_size<dev_scifi_hits_view_t>(arguments, first<host_number_of_events_t>(arguments));
  set_size<dev_scifi_track_view_t>(arguments, first<host_number_of_reconstructed_scifi_tracks_t>(arguments));
  set_size<dev_scifi_tracks_view_t>(arguments, first<host_number_of_events_t>(arguments));
  set_size<dev_scifi_multi_event_tracks_view_t>(arguments, 1);
  set_size<dev_long_track_view_t>(arguments, first<host_number_of_reconstructed_scifi_tracks_t>(arguments));
  set_size<dev_long_tracks_view_t>(arguments, first<host_number_of_events_t>(arguments));
  set_size<dev_multi_event_long_tracks_view_t>(arguments, 1);
  set_size<dev_multi_event_long_tracks_ptr_t>(arguments, 1);
  set_size<dev_used_scifi_hits_t>(arguments, first<host_scifi_hit_count_t>(arguments) / 32 + 1);
  set_size<dev_accepted_and_unused_velo_tracks_t>(arguments, size<dev_accepted_velo_tracks_t>(arguments));
  set_size<dev_used_ut_hits_offsets_t>(arguments, first<host_accumulated_number_of_ut_hits_t>(arguments) + 1);
}

void scifi_consolidate_tracks::scifi_consolidate_tracks_t::operator()(
  const ArgumentReferences<Parameters>& arguments,
  const RuntimeOptions&,
  const Constants& constants,
  const Allen::Context& context) const
{
  Allen::memset_async<dev_scifi_multi_event_tracks_view_t>(arguments, 0, context);
  Allen::memset_async<dev_scifi_tracks_view_t>(arguments, 0, context);
  Allen::memset_async<dev_used_scifi_hits_t>(arguments, 0, context);
  Allen::memset_async<dev_used_ut_hits_offsets_t>(arguments, 0, context);
  Allen::copy_async<dev_accepted_and_unused_velo_tracks_t, dev_accepted_velo_tracks_t>(arguments, context);

  auto dev_counter_long_tracks_forward = m_counter_long_tracks_forward.data(context);
  auto dev_histo_n_long_tracks_forward = m_histogram_n_long_tracks_forward.data(context);
  auto dev_histo_long_track_forward_eta = m_histogram_long_track_forward_eta.data(context);
  auto dev_histo_long_track_forward_phi = m_histogram_long_track_forward_phi.data(context);
  auto dev_histo_long_track_forward_nhits = m_histogram_long_track_forward_nhits.data(context);
  auto dev_histo_long_track_forward_qop = m_histogram_long_track_forward_qop.data(context);

  global_function(scifi_consolidate_tracks)(dim3(size<dev_event_list_t>(arguments)), property<block_dim_t>(), context)(
    arguments,
    constants.dev_looking_forward_constants,
    constants.dev_magnet_polarity.data(),
    dev_histo_n_long_tracks_forward,
    dev_counter_long_tracks_forward);

  global_function(create_scifi_views)(first<host_number_of_events_t>(arguments), 256, context)(
    arguments,
    dev_histo_long_track_forward_eta,
    dev_histo_long_track_forward_phi,
    dev_histo_long_track_forward_nhits,
    dev_histo_long_track_forward_qop);

  const bool with_ut = first<host_accumulated_number_of_ut_hits_t>(arguments) > 0;
  if (with_ut) {
    PrefixSum::prefix_sum<dev_used_ut_hits_offsets_t>(*this, arguments, context);
  }
}

template<typename F>
__device__ void populate(const SciFi::TrackHits& track, const F& assign)
{
  for (int i = 0; i < track.hitsNum; i++) {
    const auto hit_index = track.hits[i];
    assign(i, hit_index);
  }
}

template<bool with_ut, typename T>
__device__ void scifi_consolidate_tracks_impl(
  const scifi_consolidate_tracks::Parameters& parameters,
  const LookingForward::Constants* dev_looking_forward_constants,
  const float* dev_magnet_polarity,
  const T* tracks,
  Allen::Monitoring::Histogram<>::DeviceType& dev_histogram_n_long_tracks_forward,
  Allen::Monitoring::AveragingCounter<>::DeviceType& dev_n_long_tracks_forward_counter)
{

  const unsigned event_number = parameters.dev_event_list[blockIdx.x];
  const unsigned number_of_events = parameters.dev_number_of_events[0];

  const auto input_tracks_view = tracks->container(event_number);
  const int event_tracks_offset = input_tracks_view.offset();
  // TODO: Don't do this. Will be replaced when SciFi EM is updated.
  const unsigned total_number_of_tracks =
    tracks->container(number_of_events - 1).offset() + tracks->container(number_of_events - 1).size();

  const SciFi::TrackHits* event_scifi_tracks =
    parameters.dev_scifi_tracks + event_tracks_offset * SciFi::Constants::max_SciFi_tracks_per_UT_track;

  const unsigned total_number_of_scifi_hits =
    parameters.dev_scifi_hit_count[number_of_events * SciFi::Constants::n_zones];

  SciFi::ConstHits scifi_hits {parameters.dev_scifi_hits, total_number_of_scifi_hits};
  SciFi::ConstHitCount scifi_hit_count {parameters.dev_scifi_hit_count, event_number};

  const auto velo_states_view = parameters.dev_velo_states_view[event_number];

  // Create consolidated SoAs.
  SciFi::Consolidated::Tracks scifi_tracks {parameters.dev_atomics_scifi,
                                            parameters.dev_scifi_track_hit_number,
                                            parameters.dev_scifi_qop,
                                            parameters.dev_scifi_states,
                                            parameters.dev_scifi_track_ut_indices,
                                            event_number,
                                            number_of_events};
  const unsigned number_of_tracks_event = scifi_tracks.number_of_tracks(event_number);
  const unsigned event_offset = scifi_hit_count.event_offset();
  float* tracks_qop = parameters.dev_scifi_qop + parameters.dev_atomics_scifi[event_number];
  float* tracks_ghost_probability = parameters.dev_scifi_ghost_probability + parameters.dev_atomics_scifi[event_number];

  auto used_scifi_hits = parameters.dev_used_scifi_hits.get();
  auto accepted_velo_tracks = parameters.dev_accepted_and_unused_velo_tracks.get();

  if (threadIdx.x == 0) {
    dev_histogram_n_long_tracks_forward.increment(number_of_tracks_event);
    dev_n_long_tracks_forward_counter.add(number_of_tracks_event);
  }

  // Loop over tracks.
  for (unsigned i = threadIdx.x; i < number_of_tracks_event; i += blockDim.x) {

    // different ways to access velo track depend on the input track
    const auto velo_state = [&]() {
      if constexpr (with_ut) {
        const auto ut_track = input_tracks_view.track(event_scifi_tracks[i].input_track_index);
        const auto velo_track = ut_track.velo_track();
        accepted_velo_tracks[velo_track.track_container_offset() + velo_track.track_index()] = false;
        return velo_track.state(velo_states_view);
      }
      else {
        const auto velo_track = input_tracks_view.track(event_scifi_tracks[i].input_track_index);
        accepted_velo_tracks[velo_track.track_container_offset() + velo_track.track_index()] = false;
        return velo_track.state(velo_states_view);
      }
    }();

    scifi_tracks.ut_track(i) = event_scifi_tracks[i].input_track_index;
    const auto scifi_track_index = event_tracks_offset * SciFi::Constants::max_SciFi_tracks_per_UT_track + i;

    const auto curvature = parameters.dev_scifi_lf_parametrization_consolidate[scifi_track_index];
    const auto tx = parameters.dev_scifi_lf_parametrization_consolidate
                      [total_number_of_tracks * SciFi::Constants::max_SciFi_tracks_per_UT_track + scifi_track_index];
    const auto x0 =
      parameters.dev_scifi_lf_parametrization_consolidate
        [2 * total_number_of_tracks * SciFi::Constants::max_SciFi_tracks_per_UT_track + scifi_track_index];
    const auto d_ratio =
      parameters.dev_scifi_lf_parametrization_consolidate
        [3 * total_number_of_tracks * SciFi::Constants::max_SciFi_tracks_per_UT_track + scifi_track_index];
    const auto y0 =
      parameters.dev_scifi_lf_parametrization_consolidate
        [4 * total_number_of_tracks * SciFi::Constants::max_SciFi_tracks_per_UT_track + scifi_track_index];
    const auto ty =
      parameters.dev_scifi_lf_parametrization_consolidate
        [5 * total_number_of_tracks * SciFi::Constants::max_SciFi_tracks_per_UT_track + scifi_track_index];
    const auto ghost_probability =
      parameters.dev_scifi_lf_parametrization_consolidate
        [6 * total_number_of_tracks * SciFi::Constants::max_SciFi_tracks_per_UT_track + scifi_track_index];

    const auto dz = SciFi::Constants::ZEndT - LookingForward::z_mid_t;
    const MiniState scifi_state {x0 + tx * dz + curvature * dz * dz * (1.f + d_ratio * dz),
                                 y0 + ty * SciFi::Constants::ZEndT,
                                 SciFi::Constants::ZEndT,
                                 tx + 2.f * dz * curvature + 3.f * dz * dz * curvature * d_ratio,
                                 ty};

    scifi_tracks.states(i) = scifi_state;

    auto consolidated_hits = scifi_tracks.get_hits(parameters.dev_scifi_track_hits, i);
    const SciFi::TrackHits& track = event_scifi_tracks[i];

    // Update qop of the track
    const auto magSign = dev_magnet_polarity[0];
    const auto z0 = LookingForward::z_mid_t;
    const auto xVelo = velo_state.x();
    const auto yVelo = velo_state.y();
    const auto zVelo = velo_state.z();
    const auto txO = velo_state.tx();
    const auto tyO = velo_state.ty();

    // QoP for scifi tracks
    using LookingForward::MomentumEstimation::qop_calculation;
    scifi_tracks.qop(i) =
      qop_calculation(dev_looking_forward_constants, magSign, z0, x0, y0, xVelo, yVelo, zVelo, txO, tyO, tx, ty);

    // QoP for long tracks
    tracks_qop[i] =
      qop_calculation(dev_looking_forward_constants, magSign, z0, x0, y0, xVelo, yVelo, zVelo, txO, tyO, tx, ty);

    // Ghost probability
    tracks_ghost_probability[i] = ghost_probability;

    // Populate arrays
    populate(
      track,
      [&consolidated_hits, &scifi_hits, &event_offset, &used_scifi_hits](const unsigned i, const unsigned hit_index) {
        consolidated_hits.x0(i) = scifi_hits.x0(event_offset + hit_index);
        atomicOr(&used_scifi_hits[(event_offset + hit_index) / 32], 1 << ((event_offset + hit_index) % 32));
      });

    populate(track, [&consolidated_hits, &scifi_hits, &event_offset](const unsigned i, const unsigned hit_index) {
      consolidated_hits.z0(i) = scifi_hits.z0(event_offset + hit_index);
    });

    populate(track, [&consolidated_hits, &scifi_hits, &event_offset](const unsigned i, const unsigned hit_index) {
      consolidated_hits.endPointY(i) = scifi_hits.endPointY(event_offset + hit_index);
    });

    populate(track, [&consolidated_hits, &scifi_hits, &event_offset](const unsigned i, const unsigned hit_index) {
      consolidated_hits.channel(i) = scifi_hits.channel(event_offset + hit_index);
    });

    populate(track, [&consolidated_hits, &scifi_hits, &event_offset](const unsigned i, const unsigned hit_index) {
      consolidated_hits.assembled_datatype(i) = scifi_hits.assembled_datatype(event_offset + hit_index);
    });

    if constexpr (with_ut) {
      const auto ut_track = input_tracks_view.track(event_scifi_tracks[i].input_track_index);
      for (unsigned j = 0; j < ut_track.number_of_ut_hits(); j++) {
        const unsigned original_index = ut_track.hit(j).original_index();
        parameters.dev_used_ut_hits_offsets[original_index] = 1u;
      }
    }
  }
}

__global__ void scifi_consolidate_tracks::scifi_consolidate_tracks(
  scifi_consolidate_tracks::Parameters parameters,
  const LookingForward::Constants* dev_looking_forward_constants,
  const float* dev_magnet_polarity,
  Allen::Monitoring::Histogram<>::DeviceType dev_histogram_n_long_tracks_forward,
  Allen::Monitoring::AveragingCounter<>::DeviceType dev_n_long_tracks_forward_counter)
{
  const auto* ut_tracks =
    Allen::dyn_cast<const Allen::Views::UT::Consolidated::MultiEventVeloUTTracks*>(*parameters.dev_tracks_view);
  if (ut_tracks) {
    scifi_consolidate_tracks_impl<true>(
      parameters,
      dev_looking_forward_constants,
      dev_magnet_polarity,
      ut_tracks,
      dev_histogram_n_long_tracks_forward,
      dev_n_long_tracks_forward_counter);
  }
  else {
    const auto* velo_tracks =
      static_cast<const Allen::Views::Velo::Consolidated::MultiEventTracks*>(*parameters.dev_tracks_view);
    scifi_consolidate_tracks_impl<false>(
      parameters,
      dev_looking_forward_constants,
      dev_magnet_polarity,
      velo_tracks,
      dev_histogram_n_long_tracks_forward,
      dev_n_long_tracks_forward_counter);
  }
}
__device__ void scifi_consolidate_tracks::scifi_consolidate_tracks_t::monitor(
  const Allen::Views::Physics::LongTrack long_track,
  const Allen::Views::Physics::KalmanState velo_state,
  Allen::Monitoring::Histogram<>::DeviceType& dev_histo_long_track_forward_eta,
  Allen::Monitoring::Histogram<>::DeviceType& dev_histo_long_track_forward_phi,
  Allen::Monitoring::Histogram<>::DeviceType& dev_histo_long_track_forward_nhits,
  Allen::Monitoring::Histogram<>::DeviceType& dev_histo_long_track_forward_qop)
{

  const auto tx = velo_state.tx();
  const auto ty = velo_state.ty();
  const float slope2 = tx * tx + ty * ty;
  const float rho = std::sqrt(slope2);
  const auto nhits = long_track.number_of_hits();
  const auto eta = eta_from_rho(rho);
  const auto phi = std::atan2(ty, tx);
  // printf("tx %.4f , ty %.4f, nhits: %d \n", tx,ty,nhits);

  dev_histo_long_track_forward_eta.increment(eta);
  dev_histo_long_track_forward_phi.increment(phi);
  dev_histo_long_track_forward_nhits.increment(nhits);
  dev_histo_long_track_forward_qop.increment(long_track.qop());
}
