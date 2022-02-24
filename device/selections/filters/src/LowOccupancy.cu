/************************************************************************\
* (c) Copyright 2021 CERN for the benefit of the LHCb Collaboration      *
\************************************************************************/
#include "LowOccupancy.cuh"

INSTANTIATE_ALGORITHM(low_occupancy::low_occupancy_t)

void low_occupancy::low_occupancy_t::set_arguments_size(
  ArgumentReferences<Parameters> arguments,
  const RuntimeOptions&,
  const Constants&,
  const HostBuffers&) const
{

  set_size<dev_number_of_selected_events_t>(arguments, 1);
  set_size<host_number_of_selected_events_t>(arguments, 1);

  set_size<dev_event_list_output_t>(arguments, size<dev_event_list_t>(arguments));
}

void low_occupancy::low_occupancy_t::operator()(
  const ArgumentReferences<Parameters>& arguments,
  const RuntimeOptions&,
  const Constants&,
  HostBuffers&,
  const Allen::Context& context) const
{

  initialize<typename Parameters::dev_number_of_selected_events_t>(arguments, 0, context);
  initialize<typename Parameters::host_number_of_selected_events_t>(arguments, 0, context);
  initialize<typename Parameters::dev_event_list_output_t>(arguments, 0, context);

  global_function(low_occupancy)(dim3(size<typename Parameters::dev_event_list_t>(arguments)), property<block_dim_t>(), context)(arguments);
  Allen::copy<typename Parameters::host_number_of_selected_events_t, typename Parameters::dev_number_of_selected_events_t>(arguments, context);
  reduce_size<typename Parameters::dev_event_list_output_t>(arguments, first<typename Parameters::host_number_of_selected_events_t>(arguments));

}

__global__ void low_occupancy::low_occupancy(low_occupancy::Parameters parameters)
{

  const unsigned event_number = parameters.dev_event_list[blockIdx.x];
  Velo::Consolidated::ConstTracks velo_tracks {parameters.dev_offsets_velo_tracks,
                                               parameters.dev_offsets_velo_track_hit_number,
                                               event_number,
                                               parameters.dev_number_of_events[0]};
  const unsigned number_of_velo_tracks = velo_tracks.number_of_tracks(event_number);

  __shared__ int event_decision;
  if (threadIdx.x == 0) event_decision = 0;
  __syncthreads();

  const bool dec = number_of_velo_tracks >= parameters.minTracks && number_of_velo_tracks < parameters.maxTracks;
  if (dec) atomicOr( event_decision, dec );

  if ( threadIdx.x == 0 && *event_decision ) {
    const auto current_event = atomicAdd(parameters.dev_number_of_selected_events.get(), 1);
    parameters.dev_event_list_output[current_event] = mask_t {event_number};
  }
}
