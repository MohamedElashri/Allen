/*****************************************************************************\
* (c) Copyright 2018-2020 CERN for the benefit of the LHCb Collaboration      *
\*****************************************************************************/
#include "SAXPY_example.cuh"

void saxpy::saxpy_t::set_arguments_size(
  ArgumentReferences<Parameters> arguments,
  const RuntimeOptions&,
  const Constants&,
  const HostBuffers&) const
{
  set_size<dev_saxpy_output_t>(arguments, first<host_number_of_events_t>(arguments));
}

void saxpy::saxpy_t::operator()(
  const ArgumentReferences<Parameters>& arguments,
  const RuntimeOptions&,
  const Constants&,
  HostBuffers&,
  const Allen::Context& context) const
{
  global_function(saxpy)(dim3(1), property<block_dim_t>(), context)(arguments);
}

/**
 * @brief SAXPY example algorithm
 * @detail Calculates for every event y = a*x + x, where x is the number of velo tracks in one event
 */
__global__ void saxpy::saxpy(saxpy::Parameters parameters)
{
  const auto number_of_events = parameters.dev_number_of_events[0];
  for (unsigned event_number = threadIdx.x; event_number < number_of_events; event_number += blockDim.x) {
    Velo::Consolidated::ConstTracks velo_tracks {
      parameters.dev_atomics_velo, parameters.dev_velo_track_hit_number, event_number, number_of_events};
    const unsigned number_of_tracks_event = velo_tracks.number_of_tracks(event_number);

    parameters.dev_saxpy_output[event_number] =
      parameters.saxpy_scale_factor * number_of_tracks_event + number_of_tracks_event;
  }
}
