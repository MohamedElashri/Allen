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
  const auto event_tracks = parameters.dev_long_track_particles[event_number];

  for (unsigned i_scifi_track = threadIdx.x; i_scifi_track < event_tracks.size(); i_scifi_track += blockDim.x) {
    const auto track = event_tracks.particle(i_scifi_track);
    const unsigned track_idx = event_tracks.offset() + i_scifi_track;
    parameters.dev_long_track_hit_number[track_idx] = track.number_of_ids();
  }
}