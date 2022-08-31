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
    parameters.dev_multi_event_long_tracks_ptr[0] = parameters.dev_multi_event_long_tracks_view.get();
  }
}

void matching_consolidate_tracks::matching_consolidate_tracks_t::set_arguments_size(
  ArgumentReferences<Parameters> arguments,
  const RuntimeOptions&,
  const Constants&,
  const HostBuffers&) const
{

  set_size<dev_matched_track_hits_t>(
    arguments, first<host_accumulated_number_of_hits_in_matched_tracks_t>(arguments) * sizeof(SciFi::Hit));
  set_size<dev_matched_qop_t>(arguments, first<host_number_of_reconstructed_matched_tracks_t>(arguments));
  set_size<dev_matched_track_velo_indices_t>(
    arguments, first<host_number_of_reconstructed_matched_tracks_t>(arguments));
  set_size<dev_matched_track_scifi_indices_t>(
    arguments, first<host_number_of_reconstructed_matched_tracks_t>(arguments));
  set_size<dev_long_track_view_t>(arguments, first<host_number_of_reconstructed_matched_tracks_t>(arguments));
  set_size<dev_long_tracks_view_t>(arguments, first<host_number_of_events_t>(arguments));
  set_size<dev_multi_event_long_tracks_view_t>(arguments, 1);
  set_size<dev_multi_event_long_tracks_ptr_t>(arguments, 1);
}

void matching_consolidate_tracks::matching_consolidate_tracks_t::operator()(
  const ArgumentReferences<Parameters>& arguments,
  const RuntimeOptions&,
  const Constants&,
  HostBuffers&,
  const Allen::Context& context) const
{
  global_function(matching_consolidate_tracks)(
    dim3(size<dev_event_list_t>(arguments)), property<block_dim_t>(), context)(arguments);

  global_function(create_matched_views)(first<host_number_of_events_t>(arguments), 256, context)(arguments);
}

__global__ void matching_consolidate_tracks::matching_consolidate_tracks(
  matching_consolidate_tracks::Parameters parameters)
{
  const unsigned event_number = parameters.dev_event_list[blockIdx.x];

  const SciFi::MatchedTrack* event_matched_tracks =
    parameters.dev_matched_tracks + event_number * TrackMatchingConsts::max_num_tracks;

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
  }
}
