/*****************************************************************************\
* (c) Copyright 2018-2020 CERN for the benefit of the LHCb Collaboration      *
\*****************************************************************************/
#include "ConsolidateSciFiSeeding.cuh"
#include "hybrid_seeding_helpers.cuh"

INSTANTIATE_ALGORITHM(seed_confirmTracks_consolidate::seed_confirmTracks_consolidate_t);

__global__ void create_scifi_views(seed_confirmTracks_consolidate::Parameters parameters)
{
  const unsigned number_of_events = parameters.dev_number_of_events[0];
  const unsigned event_number = blockIdx.x;

  const auto event_tracks_offset = parameters.dev_atomics_scifi[event_number];
  const auto event_number_of_tracks = parameters.dev_atomics_scifi[event_number + 1] - event_tracks_offset;
  for (unsigned track_index = threadIdx.x; track_index < event_number_of_tracks; track_index += blockDim.x) {
    new (parameters.dev_scifi_track_view + event_tracks_offset + track_index)
      Allen::Views::SciFi::Consolidated::Track {parameters.dev_scifi_hits_view,
                                                parameters.dev_seeding_qop,
                                                parameters.dev_atomics_scifi,
                                                parameters.dev_seeding_hit_number,
                                                track_index,
                                                event_number};
  }

  if (threadIdx.x == 0) {
    new (parameters.dev_scifi_hits_view + event_number)
      Allen::Views::SciFi::Consolidated::Hits {parameters.dev_seeding_track_hits,
                                               parameters.dev_atomics_scifi,
                                               parameters.dev_seeding_hit_number,
                                               event_number,
                                               number_of_events};

    new (parameters.dev_scifi_tracks_view + event_number) Allen::Views::SciFi::Consolidated::Tracks {
      parameters.dev_scifi_track_view, parameters.dev_atomics_scifi, event_number};
  }

  if (blockIdx.x == 0 && threadIdx.x == 0) {
    new (parameters.dev_scifi_multi_event_tracks_view)
      Allen::Views::SciFi::Consolidated::MultiEventTracks {parameters.dev_scifi_tracks_view, number_of_events};
  }
}

void seed_confirmTracks_consolidate::seed_confirmTracks_consolidate_t::set_arguments_size(
  ArgumentReferences<Parameters> arguments,
  const RuntimeOptions&,
  const Constants&) const
{
  set_size<dev_seeding_track_hits_t>(
    arguments, first<host_accumulated_number_of_hits_in_scifi_tracks_t>(arguments) * sizeof(SciFi::Hit));
  set_size<dev_seeding_qop_t>(arguments, first<host_number_of_reconstructed_seeding_tracks_t>(arguments));
  set_size<dev_seeding_states_t>(arguments, first<host_number_of_reconstructed_seeding_tracks_t>(arguments));
  set_size<dev_scifi_hits_view_t>(arguments, first<host_number_of_events_t>(arguments));
  set_size<dev_scifi_track_view_t>(arguments, first<host_number_of_reconstructed_seeding_tracks_t>(arguments));
  set_size<dev_scifi_tracks_view_t>(arguments, first<host_number_of_events_t>(arguments));
  set_size<dev_scifi_multi_event_tracks_view_t>(arguments, 1);
  set_size<dev_used_scifi_hits_t>(arguments, first<host_scifi_hit_count_t>(arguments));
}

void seed_confirmTracks_consolidate::seed_confirmTracks_consolidate_t::init()
{
#ifndef ALLEN_STANDALONE
  m_seed_tracks = new Gaudi::Accumulators::Counter<>(this, "n_seed_tracks");
  histogram_n_scifi_seeds = new gaudi_monitoring::Lockable_Histogram<> {
    {this, "n_scifi_seeds_event", "n_scifi_seeds_event", {80, 0, 200, {}, {}}}, {}};
  histogram_scifi_track_eta =
    new gaudi_monitoring::Lockable_Histogram<> {{this,
                                                 "scifi_track_eta",
                                                 "#eta",
                                                 {property<histogram_scifi_track_eta_nbins_t>(),
                                                  property<histogram_scifi_track_eta_min_t>(),
                                                  property<histogram_scifi_track_eta_max_t>()}},
                                                {}};
  histogram_scifi_track_phi =
    new gaudi_monitoring::Lockable_Histogram<> {{this,
                                                 "scifi_track_phi",
                                                 "#phi",
                                                 {property<histogram_scifi_track_phi_nbins_t>(),
                                                  property<histogram_scifi_track_phi_min_t>(),
                                                  property<histogram_scifi_track_phi_max_t>()}},
                                                {}};
  histogram_scifi_track_nhits =
    new gaudi_monitoring::Lockable_Histogram<> {{this,
                                                 "scifi_track_nhits",
                                                 "N. hits / track",
                                                 {property<histogram_scifi_track_nhits_nbins_t>(),
                                                  property<histogram_scifi_track_nhits_min_t>(),
                                                  property<histogram_scifi_track_nhits_max_t>()}},
                                                {}};
#endif
}

//===========================================================================================
// Calculate momentum, given T state only, adapted from
// https://gitlab.cern.ch/lhcb/Rec/-/blob/master/Tr/TrackTools/src/FastMomentumEstimate.cpp
//===========================================================================================
__device__ float qop_seeding_calculation(const float magSign, const MiniState seeding_state, bool tCubicFit)
{
  const float tx = seeding_state.tx;
  const float ty = seeding_state.ty;
  const float x = seeding_state.x;
  const float z = seeding_state.z;

  const float m_paramsTParab[4] = {-6.30991, -4.83533, -12.9192, 4.23025e-08};
  const float m_paramsTCubic[4] = {-6.34025, -4.85287, -12.4491, 4.25461e-08};

  float qop = 0.f;
  const float x0 = x - tx * z;
  const auto& params = (tCubicFit ? m_paramsTCubic : m_paramsTParab);
  const auto p = params[0] + params[1] * tx * tx + params[2] * ty * ty + params[3] * x0 * x0;

  const float scale_factor = 1.f * magSign; // is there a way to get the scale_factor from the constants?
  const float denom = p * scale_factor * 1e6f * (-1.f);

  if (std::fabs(scale_factor) < 1e-6f) {
    qop = 0.01f / Gaudi::Units::GeV;
  }
  else {
    qop = x0 / denom;
  }
  return qop;
}

void seed_confirmTracks_consolidate::seed_confirmTracks_consolidate_t::operator()(
  const ArgumentReferences<Parameters>& arguments,
  const RuntimeOptions&,
  const Constants& constants,
  const Allen::Context& context) const
{
  Allen::memset_async<dev_scifi_multi_event_tracks_view_t>(arguments, 0, context);
  Allen::memset_async<dev_scifi_tracks_view_t>(arguments, 0, context);
  Allen::memset_async<dev_used_scifi_hits_t>(arguments, 0, context);

  auto dev_histogram_scifi_track_eta =
    make_device_buffer<unsigned>(arguments, property<histogram_scifi_track_eta_nbins_t>());
  auto dev_histogram_scifi_track_phi =
    make_device_buffer<unsigned>(arguments, property<histogram_scifi_track_phi_nbins_t>());
  auto dev_histogram_scifi_track_nhits =
    make_device_buffer<unsigned>(arguments, property<histogram_scifi_track_nhits_nbins_t>());
  auto dev_histogram_scifi_n_tracks = make_device_buffer<unsigned>(arguments, 80u);
  auto dev_scifi_n_tracks_counter = make_device_buffer<unsigned>(arguments, 1u);
  Allen::memset_async(
    dev_histogram_scifi_track_eta.data(), 0, dev_histogram_scifi_track_eta.size() * sizeof(unsigned), context);
  Allen::memset_async(
    dev_histogram_scifi_track_phi.data(), 0, dev_histogram_scifi_track_phi.size() * sizeof(unsigned), context);
  Allen::memset_async(
    dev_histogram_scifi_track_nhits.data(), 0, dev_histogram_scifi_track_nhits.size() * sizeof(unsigned), context);
  Allen::memset_async(
    dev_histogram_scifi_n_tracks.data(), 0, dev_histogram_scifi_n_tracks.size() * sizeof(unsigned), context);
  Allen::memset_async(
    dev_scifi_n_tracks_counter.data(), 0, dev_scifi_n_tracks_counter.size() * sizeof(unsigned), context);

  global_function(seed_confirmTracks_consolidate)(
    dim3(size<dev_event_list_t>(arguments)), property<block_dim_t>(), context)(
    arguments,
    constants.dev_magnet_polarity.data(),
    dev_histogram_scifi_track_eta.get(),
    dev_histogram_scifi_track_phi.get(),
    dev_histogram_scifi_track_nhits.get(),
    dev_histogram_scifi_n_tracks.get(),
    dev_scifi_n_tracks_counter.get());

  global_function(create_scifi_views)(first<host_number_of_events_t>(arguments), 256, context)(arguments);

#ifndef ALLEN_STANDALONE
  // Monitoring
  gaudi_monitoring::fill(
    arguments,
    context,
    std::tuple {std::tuple {dev_histogram_scifi_track_eta.get(),
                            histogram_scifi_track_eta,
                            property<histogram_scifi_track_eta_min_t>(),
                            property<histogram_scifi_track_eta_max_t>()},
                std::tuple {dev_histogram_scifi_track_phi.get(),
                            histogram_scifi_track_phi,
                            property<histogram_scifi_track_phi_min_t>(),
                            property<histogram_scifi_track_phi_max_t>()},
                std::tuple {dev_histogram_scifi_track_nhits.get(),
                            histogram_scifi_track_nhits,
                            property<histogram_scifi_track_nhits_min_t>(),
                            property<histogram_scifi_track_nhits_max_t>()},
                std::tuple {dev_histogram_scifi_n_tracks.get(), histogram_n_scifi_seeds, 0, 200},
                std::tuple {dev_scifi_n_tracks_counter.get(), m_seed_tracks}});
#endif
}

template<typename F>
__device__ void populate(const SciFi::Seeding::Track& track, const F& assign)
{
  for (int i = 0; i < track.number_of_hits; i++) {
    const auto hit_index = track.hits[i];
    assign(i, hit_index);
  }
}

__global__ void seed_confirmTracks_consolidate::seed_confirmTracks_consolidate(
  seed_confirmTracks_consolidate::Parameters parameters,
  const float* dev_magnet_polarity,
  gsl::span<unsigned> dev_histogram_scifi_track_eta,
  gsl::span<unsigned> dev_histogram_scifi_track_phi,
  gsl::span<unsigned> dev_histogram_scifi_track_nhits,
  gsl::span<unsigned> dev_histogram_scifi_n_tracks,
  gsl::span<unsigned> dev_scifi_n_tracks_counter)
{
  const unsigned event_number = parameters.dev_event_list[blockIdx.x];
  const unsigned number_of_events = parameters.dev_number_of_events[0];

  const SciFi::Seeding::Track* event_scifi_seeds =
    parameters.dev_seeding_tracks + event_number * SciFi::Constants::Nmax_seeds;

  const unsigned total_number_of_scifi_hits =
    parameters.dev_scifi_hit_count[number_of_events * SciFi::Constants::n_mat_groups_and_mats];

  SciFi::ConstHits scifi_hits {parameters.dev_scifi_hits, total_number_of_scifi_hits};
  SciFi::ConstHitCount scifi_hit_count {parameters.dev_scifi_hit_count, event_number};

  // Create consolidated SoAs.
  SciFi::Consolidated::Seeds scifi_seeds {parameters.dev_atomics_scifi,
                                          parameters.dev_seeding_hit_number,
                                          parameters.dev_seeding_states,
                                          event_number,
                                          number_of_events};
  const unsigned number_of_tracks_event = scifi_seeds.number_of_tracks(event_number);
  float* tracks_qop = parameters.dev_seeding_qop + parameters.dev_atomics_scifi[event_number];
  auto used_scifi_hits = parameters.dev_used_scifi_hits.get();

  if (number_of_tracks_event < 200) {
    unsigned bin = std::floor(number_of_tracks_event / 2.5);
    dev_histogram_scifi_n_tracks[bin]++;
  }
  dev_scifi_n_tracks_counter[0] += number_of_tracks_event;

  // Loop over tracks.
  for (unsigned i = threadIdx.x; i < number_of_tracks_event; i += blockDim.x) {

    const SciFi::Seeding::Track& scifiseed = event_scifi_seeds[i];

    const auto dz = SciFi::Constants::ZEndT - hybrid_seeding::z_ref;

    const MiniState seeding_state {scifiseed.xFromDz(dz),
                                   scifiseed.yFromDz(dz),
                                   SciFi::Constants::ZEndT,
                                   scifiseed.xSlopeFromDz(dz),
                                   scifiseed.ySlope()};

    scifi_seeds.states(i) = seeding_state;

    const auto magSign = dev_magnet_polarity[0];
    tracks_qop[i] = qop_seeding_calculation(magSign, seeding_state, true);

    auto consolidated_hits = scifi_seeds.get_hits(parameters.dev_seeding_track_hits, i);

    // Populate arrays
    populate(
      scifiseed, [&consolidated_hits, &scifi_hits, &used_scifi_hits](const unsigned i, const unsigned hit_index) {
        consolidated_hits.x0(i) = scifi_hits.x0(hit_index);
        used_scifi_hits[hit_index] = 1;
      });

    populate(scifiseed, [&consolidated_hits, &scifi_hits](const unsigned i, const unsigned hit_index) {
      consolidated_hits.z0(i) = scifi_hits.z0(hit_index);
    });

    populate(scifiseed, [&consolidated_hits, &scifi_hits](const unsigned i, const unsigned hit_index) {
      consolidated_hits.endPointY(i) = scifi_hits.endPointY(hit_index);
    });

    populate(scifiseed, [&consolidated_hits, &scifi_hits](const unsigned i, const unsigned hit_index) {
      consolidated_hits.channel(i) = scifi_hits.channel(hit_index);
    });

    populate(scifiseed, [&consolidated_hits, &scifi_hits](const unsigned i, const unsigned hit_index) {
      consolidated_hits.assembled_datatype(i) = scifi_hits.assembled_datatype(hit_index);
    });
    seed_confirmTracks_consolidate::seed_confirmTracks_consolidate_t::monitor(
      parameters,
      scifiseed,
      seeding_state,
      dev_histogram_scifi_track_eta,
      dev_histogram_scifi_track_phi,
      dev_histogram_scifi_track_nhits);
  }
}
__device__ void seed_confirmTracks_consolidate::seed_confirmTracks_consolidate_t::monitor(
  const seed_confirmTracks_consolidate::Parameters& parameters,
  SciFi::Seeding::Track scifi_track,
  MiniState scifi_state,
  gsl::span<unsigned> dev_histogram_scifi_track_eta,
  gsl::span<unsigned> dev_histogram_scifi_track_phi,
  gsl::span<unsigned> dev_histogram_scifi_track_nhits)
{

  const auto tx = scifi_state.tx;
  const auto ty = scifi_state.ty;
  const float slope2 = tx * tx + ty * ty;
  const float rho = std::sqrt(slope2);
  const unsigned nhits = scifi_track.number_of_hits;
  const auto eta = eta_from_rho(rho);
  const auto phi = std::atan2(ty, tx);
  // printf("tx %.4f , ty %.4f, nhits: %d \n", tx,ty,nhits);

  if (eta > parameters.histogram_scifi_track_eta_min && eta < parameters.histogram_scifi_track_eta_max) {
    const unsigned int bin = static_cast<unsigned int>(
      (eta - parameters.histogram_scifi_track_eta_min) * parameters.histogram_scifi_track_eta_nbins /
      (parameters.histogram_scifi_track_eta_max - parameters.histogram_scifi_track_eta_min));
    ++dev_histogram_scifi_track_eta[bin];
  }
  if (phi > parameters.histogram_scifi_track_phi_min && phi < parameters.histogram_scifi_track_phi_max) {
    const unsigned int bin = static_cast<unsigned int>(
      (phi - parameters.histogram_scifi_track_phi_min) * parameters.histogram_scifi_track_phi_nbins /
      (parameters.histogram_scifi_track_phi_max - parameters.histogram_scifi_track_phi_min));
    ++dev_histogram_scifi_track_phi[bin];
  }
  if (nhits > parameters.histogram_scifi_track_nhits_min && nhits < parameters.histogram_scifi_track_nhits_max) {
    const unsigned int bin = static_cast<unsigned int>(
      (nhits - parameters.histogram_scifi_track_nhits_min) * parameters.histogram_scifi_track_nhits_nbins /
      (parameters.histogram_scifi_track_nhits_max - parameters.histogram_scifi_track_nhits_min));
    ++dev_histogram_scifi_track_nhits[bin];
  }
}
