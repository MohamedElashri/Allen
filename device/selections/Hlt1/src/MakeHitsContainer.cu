/*****************************************************************************\
* (c) Copyright 2020 CERN for the benefit of the LHCb Collaboration           *
\*****************************************************************************/
#include "MakeHitsContainer.cuh"

INSTANTIATE_ALGORITHM(make_hits_container::make_hits_container_t)

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
  const auto event_tracks = parameters.dev_long_track_particles[event_number];
  
  const unsigned n_scifi_tracks = event_tracks.size();
  for (unsigned i_scifi_track = threadIdx.x; i_scifi_track < n_scifi_tracks; i_scifi_track += blockDim.x) {
    const auto track = event_tracks.particle(i_scifi_track);
    const unsigned n_hits = track.number_of_ids();
    const unsigned hits_offset = parameters.dev_hits_offsets[i_scifi_track + event_tracks.offset()];
    unsigned* track_hits_container = parameters.dev_hits_container + hits_offset;
    for (unsigned i_hit = 0; i_hit < n_hits; i_hit++) {
      track_hits_container[i_hit] = track.id(i_hit);
    }
  }
}