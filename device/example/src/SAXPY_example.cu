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
#include "SAXPY_example.cuh"

INSTANTIATE_ALGORITHM(saxpy::saxpy_t)

void saxpy::saxpy_t::set_arguments_size(
  ArgumentReferences<Parameters> arguments,
  const RuntimeOptions&,
  const Constants&) const
{
  set_size<dev_saxpy_output_t>(arguments, first<host_number_of_events_t>(arguments));
}

void saxpy::saxpy_t::operator()(
  const ArgumentReferences<Parameters>& arguments,
  const RuntimeOptions&,
  const Constants&,
  const Allen::Context& context) const
{
  global_function(saxpy)(dim3(1), m_block_dim, context)(arguments, m_saxpy_factor);
}

/**
 * @brief SAXPY example algorithm
 * @detail Calculates for every event y = a*x + x, where x is the number of velo tracks in one event
 */
__global__ void saxpy::saxpy(saxpy::Parameters parameters, const float saxpy_scale_factor)
{
  const auto number_of_events = parameters.dev_number_of_events[0];
  for (unsigned event_number = threadIdx.x; event_number < number_of_events; event_number += blockDim.x) {
    Velo::Consolidated::ConstTracks velo_tracks {
      parameters.dev_atomics_velo, parameters.dev_velo_track_hit_number, event_number, number_of_events};
    const unsigned number_of_tracks_event = velo_tracks.number_of_tracks(event_number);

    parameters.dev_saxpy_output[event_number] = saxpy_scale_factor * number_of_tracks_event + number_of_tracks_event;
  }
}
