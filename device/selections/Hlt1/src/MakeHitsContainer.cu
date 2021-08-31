/*****************************************************************************\
* (c) Copyright 2020 CERN for the benefit of the LHCb Collaboration           *
\*****************************************************************************/
#include "MakeHitsContainer.cuh"

void make_hits_container::make_hits_container_t::set_arguments_size(
  ArgumentReferences<Parameters> arguments,
  const RuntimeOptions&,
  const Constants&,
  const HostBuffers&) const
{
  set_size<dev_hits_container_t>(arguments, first<host_hits_container_size_t>(arguments));
}

void make_hits_container::make_hits_container_t::operator()(
  const ArgumentReferences<Parameters>& arguments,
  const RuntimeOptions&,
  const Constants&,
  HostBuffers&,
  const Allen::Context& context) const
{
  global_function(make_container)(dim3(size<dev_event_list_t>(arguments)), property<block_dim_t>(), context)(arguments);
}

__global__ void make_hits_container::make_container(make_hits_container::Parameters parameters)
{
  const unsigned event_number = parameters.dev_event_list[blockIdx.x];
  const unsigned number_of_events = parameters.dev_number_of_events[0];
  // const unsigned event_hits_offset = parameters.dev_hits_offsets[event_number];
  //  unsigned* event_hits_container = parameters.dev_hits_container + event_hits_offset;

  // Create velo tracks.
  Velo::Consolidated::Tracks const velo_tracks {
    parameters.dev_atomics_velo, parameters.dev_velo_track_hit_number, event_number, number_of_events};

  // Create UT tracks.
  UT::Consolidated::ConstExtendedTracks ut_tracks {parameters.dev_atomics_ut,
                                                   parameters.dev_ut_track_hit_number,
                                                   parameters.dev_ut_qop,
                                                   parameters.dev_ut_track_velo_indices,
                                                   event_number,
                                                   number_of_events};

  // Create SciFi tracks.
  SciFi::Consolidated::ConstTracks scifi_tracks {parameters.dev_atomics_scifi,
                                                 parameters.dev_scifi_track_hit_number,
                                                 parameters.dev_scifi_qop,
                                                 parameters.dev_scifi_states,
                                                 parameters.dev_scifi_track_ut_indices,
                                                 event_number,
                                                 number_of_events};

  const unsigned n_scifi_tracks = scifi_tracks.number_of_tracks(event_number);
  for (unsigned i_scifi_track = threadIdx.x; i_scifi_track < n_scifi_tracks; i_scifi_track += blockDim.x) {
    const int i_ut_track = scifi_tracks.ut_track(i_scifi_track);
    const int i_velo_track = ut_tracks.velo_track(i_ut_track);
    const unsigned n_velo_hits = velo_tracks.number_of_hits(i_velo_track);
    const unsigned n_ut_hits = ut_tracks.number_of_hits(i_ut_track);
    const unsigned n_scifi_hits = scifi_tracks.number_of_hits(i_scifi_track);
    const unsigned track_index = scifi_tracks.tracks_offset(event_number) + i_scifi_track;

    Velo::Consolidated::ConstHits velo_hits = velo_tracks.get_hits(parameters.dev_velo_track_hits, i_velo_track);
    UT::Consolidated::ConstHits ut_hits = ut_tracks.get_hits(parameters.dev_ut_track_hits, i_ut_track);
    SciFi::Consolidated::ConstHits scifi_hits = scifi_tracks.get_hits(parameters.dev_scifi_track_hits, i_scifi_track);

    const unsigned hits_offset = parameters.dev_hits_offsets[track_index];
    unsigned* track_hits_container = parameters.dev_hits_container + hits_offset;
    // Fill VELO hits.
    for (unsigned i_velo_hit = 0; i_velo_hit < n_velo_hits; i_velo_hit++) {
      track_hits_container[i_velo_hit] = velo_hits.id(i_velo_hit);
    }
    // Fill UT hits.
    for (unsigned i_ut_hit = 0; i_ut_hit < n_ut_hits; i_ut_hit++) {
      track_hits_container[n_velo_hits + i_ut_hit] = ut_hits.id(i_ut_hit);
    }
    // Fill SciFi hits.
    for (unsigned i_scifi_hit = 0; i_scifi_hit < n_scifi_hits; i_scifi_hit++) {
      track_hits_container[n_velo_hits + n_ut_hits + i_scifi_hit] = scifi_hits.id(i_scifi_hit);
    }
  }
}