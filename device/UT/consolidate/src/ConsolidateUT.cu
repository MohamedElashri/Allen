/*****************************************************************************\
* (c) Copyright 2018-2020 CERN for the benefit of the LHCb Collaboration      *
\*****************************************************************************/
#include "ConsolidateUT.cuh"

INSTANTIATE_ALGORITHM(ut_consolidate_tracks::ut_consolidate_tracks_t)

__global__ void create_ut_views(ut_consolidate_tracks::Parameters parameters)
{
  const unsigned number_of_events = parameters.dev_number_of_events[0];
  const unsigned event_number = blockIdx.x;

  const auto event_tracks_offset = parameters.dev_atomics_ut[event_number];
  const auto event_number_of_tracks = parameters.dev_atomics_ut[event_number + 1] - event_tracks_offset;
  const auto event_ut_track_velo_indices = parameters.dev_ut_track_velo_indices + event_tracks_offset;
  for (unsigned track_index = threadIdx.x; track_index < event_number_of_tracks; track_index += blockDim.x) {
    const auto velo_track_index = event_ut_track_velo_indices[track_index];
    new (parameters.dev_ut_track_view + event_tracks_offset + track_index)
      Allen::Views::UT::Consolidated::Track {parameters.dev_ut_hits_view,
                                             &parameters.dev_velo_tracks_view[event_number].track(velo_track_index),
                                             parameters.dev_ut_track_velo_indices,
                                             parameters.dev_ut_track_params,
                                             parameters.dev_atomics_ut,
                                             parameters.dev_ut_track_hit_number,
                                             event_number_of_tracks,
                                             track_index,
                                             event_number};
  }

  if (threadIdx.x == 0) {
    new (parameters.dev_ut_hits_view + event_number)
      Allen::Views::UT::Consolidated::Hits {parameters.dev_ut_track_hits,
                                            parameters.dev_atomics_ut,
                                            parameters.dev_ut_track_hit_number,
                                            event_number,
                                            number_of_events};

    new (parameters.dev_ut_tracks_view + event_number)
      Allen::Views::UT::Consolidated::Tracks {parameters.dev_ut_track_view, parameters.dev_atomics_ut, event_number};
  }

  if (blockIdx.x == 0 && threadIdx.x == 0) {
    new (parameters.dev_ut_multi_event_tracks_view)
      Allen::Views::UT::Consolidated::MultiEventTracks {parameters.dev_ut_tracks_view, number_of_events};

    parameters.dev_imec_ut_tracks[0] = parameters.dev_ut_multi_event_tracks_view;
  }
}

void ut_consolidate_tracks::ut_consolidate_tracks_t::set_arguments_size(
  ArgumentReferences<Parameters> arguments,
  const RuntimeOptions&,
  const Constants&) const
{
  set_size<dev_ut_track_hits_t>(
    arguments, first<host_accumulated_number_of_ut_hits_t>(arguments) * UT::Consolidated::Hits::element_size);
  set_size<dev_ut_track_velo_indices_t>(arguments, first<host_number_of_reconstructed_ut_tracks_t>(arguments));
  set_size<dev_ut_qop_t>(arguments, first<host_number_of_reconstructed_ut_tracks_t>(arguments));
  set_size<dev_ut_track_params_t>(arguments, 4 * first<host_number_of_reconstructed_ut_tracks_t>(arguments));
  set_size<dev_ut_hits_view_t>(arguments, first<host_number_of_events_t>(arguments));
  set_size<dev_ut_track_view_t>(arguments, first<host_number_of_reconstructed_ut_tracks_t>(arguments));
  set_size<dev_ut_tracks_view_t>(arguments, first<host_number_of_events_t>(arguments));
  set_size<dev_ut_multi_event_tracks_view_t>(arguments, 1);
  set_size<dev_imec_ut_tracks_t>(arguments, 1);
}

void ut_consolidate_tracks::ut_consolidate_tracks_t::operator()(
  const ArgumentReferences<Parameters>& arguments,
  const RuntimeOptions&,
  const Constants& constants,
  const Allen::Context& context) const
{
  Allen::memset_async<dev_ut_multi_event_tracks_view_t>(arguments, 0, context);
  Allen::memset_async<dev_ut_tracks_view_t>(arguments, 0, context);

  global_function(ut_consolidate_tracks)(dim3(size<dev_event_list_t>(arguments)), property<block_dim_t>(), context)(
    arguments, constants.dev_unique_x_sector_layer_offsets.data());

  global_function(create_ut_views)(first<host_number_of_events_t>(arguments), 256, context)(arguments);
}

template<typename F>
__device__ void populate(const UT::TrackHits& track, const F& assign)
{
  int hit_number = 0;
  for (unsigned i = 0; i < UT::Constants::n_layers; ++i) {
    const auto hit_index = track.hits[i];
    if (hit_index != -1) {
      assign(hit_number++, hit_index);
    }
  }
}

template<typename F>
__device__ void populate_plane_code(const UT::TrackHits& track, const F& assign)
{
  int hit_number = 0;
  for (unsigned i = 0; i < UT::Constants::n_layers; ++i) {
    const auto hit_index = track.hits[i];
    if (hit_index != -1) {
      assign(hit_number++, i);
    }
  }
}

__global__ void ut_consolidate_tracks::ut_consolidate_tracks(
  ut_consolidate_tracks::Parameters parameters,
  const unsigned* dev_unique_x_sector_layer_offsets)
{
  const unsigned event_number = parameters.dev_event_list[blockIdx.x];
  const unsigned number_of_events = parameters.dev_number_of_events[0];
  const unsigned number_of_unique_x_sectors = dev_unique_x_sector_layer_offsets[UT::Constants::n_layers];
  const unsigned total_number_of_hits = parameters.dev_ut_hit_offsets[number_of_events * number_of_unique_x_sectors];
  const UT::TrackHits* event_veloUT_tracks = parameters.dev_ut_tracks + event_number * UT::Constants::max_num_tracks;

  const UT::HitOffsets ut_hit_offsets {
    parameters.dev_ut_hit_offsets, event_number, number_of_unique_x_sectors, dev_unique_x_sector_layer_offsets};
  const auto event_offset = ut_hit_offsets.event_offset();

  UT::ConstHits ut_hits {parameters.dev_ut_hits, total_number_of_hits};

  // Create consolidated SoAs.
  UT::Consolidated::ExtendedTracks ut_tracks {parameters.dev_atomics_ut,
                                              parameters.dev_ut_track_hit_number,
                                              parameters.dev_ut_qop,
                                              parameters.dev_ut_track_velo_indices,
                                              event_number,
                                              number_of_events};

  const unsigned number_of_tracks_event = ut_tracks.number_of_tracks(event_number);
  const unsigned event_tracks_offset = ut_tracks.tracks_offset(event_number);
  float* event_ut_track_params = parameters.dev_ut_track_params + 4 * event_tracks_offset;

  // Loop over tracks.
  for (unsigned i = threadIdx.x; i < number_of_tracks_event; i += blockDim.x) {
    const UT::TrackHits& track = event_veloUT_tracks[i];

    // TODO: Should we just store the velo track index in dev_ut_track_params?
    ut_tracks.velo_track(i) = track.velo_track_index;
    // TODO: For now, the qop buffer is needed for the Rec track converter. We
    // should eventually use views for this too.
    ut_tracks.qop(i) = track.qop;
    event_ut_track_params[i] = track.qop;
    event_ut_track_params[i + number_of_tracks_event] = track.x;
    event_ut_track_params[i + 2 * number_of_tracks_event] = track.z;
    event_ut_track_params[i + 3 * number_of_tracks_event] = track.tx;

    UT::Consolidated::Hits consolidated_hits = ut_tracks.get_hits(parameters.dev_ut_track_hits, i);

    // Populate the consolidated hits.
    populate(track, [&consolidated_hits, &ut_hits, &event_offset](const unsigned hit_number, const unsigned j) {
      consolidated_hits.yBegin(hit_number) = ut_hits.yBegin(j + event_offset);
    });

    populate(track, [&consolidated_hits, &ut_hits, &event_offset](const unsigned hit_number, const unsigned j) {
      consolidated_hits.yEnd(hit_number) = ut_hits.yEnd(j + event_offset);
    });

    populate(track, [&consolidated_hits, &ut_hits, &event_offset](const unsigned hit_number, const unsigned j) {
      consolidated_hits.zAtYEq0(hit_number) = ut_hits.zAtYEq0(j + event_offset);
    });

    populate(track, [&consolidated_hits, &ut_hits, &event_offset](const unsigned hit_number, const unsigned j) {
      consolidated_hits.xAtYEq0(hit_number) = ut_hits.xAtYEq0(j + event_offset);
    });

    populate(track, [&consolidated_hits, &ut_hits, &event_offset](const unsigned hit_number, const unsigned j) {
      consolidated_hits.id(hit_number) = ut_hits.id(j + event_offset);
    });

    populate(track, [&consolidated_hits, &ut_hits, &event_offset](const unsigned hit_number, const unsigned j) {
      consolidated_hits.weight(hit_number) = ut_hits.weight(j + event_offset);
    });

    populate_plane_code(track, [&consolidated_hits](const unsigned hit_number, const unsigned j) {
      consolidated_hits.plane_code(hit_number) = static_cast<uint8_t>(j);
    });
  }
}

void ut_consolidate_tracks::lhcb_id_container_checks::operator()(
  const ArgumentReferences<Parameters>& arguments,
  const RuntimeOptions&,
  const Constants&,
  const Allen::Context& context) const
{
  const auto ut_multi_event_tracks_view =
    make_host_buffer<Parameters::dev_ut_multi_event_tracks_view_t>(arguments, context);
  const Allen::Views::UT::Consolidated::MultiEventTracks* multiev_id_cont =
    reinterpret_cast<const Allen::Views::UT::Consolidated::MultiEventTracks*>(ut_multi_event_tracks_view.data());

  // Conditions to check
  const bool size_is_number_of_events =
    ut_multi_event_tracks_view[0].number_of_events() == multiev_id_cont->number_of_events();
  bool equal_number_of_tracks_and_sequences = true;
  bool lhcb_ids_never_zero = true;
  bool ut_ids_have_ut_preamble = true;
  bool velo_ids_have_velo_preamble = true;

  for (unsigned event_number = 0; event_number < ut_multi_event_tracks_view[0].number_of_events(); ++event_number) {
    const auto& tracks = ut_multi_event_tracks_view[0].container(event_number);
    const auto& id_cont = multiev_id_cont->container(event_number);
    equal_number_of_tracks_and_sequences &= tracks.size() == id_cont.number_of_id_sequences();

    for (unsigned sequence_index = 0; sequence_index < tracks.size(); ++sequence_index) {
      const auto& track = tracks.track(sequence_index);
      const auto& velo_track = track.velo_track();

      // In order to avoid recursive calls, VELO hits need to be accessed by the
      // VELO track.
      for (unsigned id_index = 0; id_index < track.number_of_total_hits() - track.number_of_ut_hits(); id_index++) {
        lhcb_ids_never_zero &= velo_track.id(id_index) != 0;
        velo_ids_have_velo_preamble &= lhcb_id::is_velo(velo_track.id(id_index));
      }

      for (unsigned id_index = 0; id_index < track.number_of_ut_hits(); id_index++) {
        lhcb_ids_never_zero &= track.id(id_index) != 0;
        ut_ids_have_ut_preamble &= lhcb_id::is_ut(track.id(id_index));
      }
    }
  }

  require(size_is_number_of_events, "Require that number of events is equal to MultiEventLHCbIDContainer size");
  require(
    equal_number_of_tracks_and_sequences,
    "Require that the number of tracks equals the number of LHCb ID sequences for all events");
  require(lhcb_ids_never_zero, "Require that LHCb IDs are never zero");
  require(velo_ids_have_velo_preamble, "Require that LHCb IDs of VELO hits have VELO preamble");
  require(ut_ids_have_ut_preamble, "Require that LHCb IDs of UT hits have UT preamble");
}
