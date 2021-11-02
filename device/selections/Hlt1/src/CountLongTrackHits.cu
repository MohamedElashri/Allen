/*****************************************************************************\
* (c) Copyright 2018-2020 CERN for the benefit of the LHCb Collaboration      *
\*****************************************************************************/
#include "CountLongTrackHits.cuh"

INSTANTIATE_ALGORITHM(count_long_track_hits::count_long_track_hits_t)

void count_long_track_hits::count_long_track_hits_t::set_arguments_size(
  ArgumentReferences<Parameters> arguments,
  const RuntimeOptions&,
  const Constants&,
  const HostBuffers&) const
{
  set_size<dev_long_track_hit_number_t>(arguments, first<host_number_of_reconstructed_scifi_tracks_t>(arguments));
}

void count_long_track_hits::count_long_track_hits_t::operator()(
  const ArgumentReferences<Parameters>& arguments,
  const RuntimeOptions&,
  const Constants&,
  HostBuffers&,
  const Allen::Context& context) const
{
  global_function(count_hits)(dim3(size<dev_event_list_t>(arguments)), property<block_dim_t>(), context)(arguments);
}

__global__ void count_long_track_hits::count_hits(count_long_track_hits::Parameters parameters)
{
  const unsigned event_number = parameters.dev_event_list[blockIdx.x];
  const unsigned number_of_events = parameters.dev_number_of_events[0];

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
    const unsigned track_idx = scifi_tracks.tracks_offset(event_number) + i_scifi_track;
    parameters.dev_long_track_hit_number[track_idx] = n_velo_hits + n_ut_hits + n_scifi_hits;
  }
}