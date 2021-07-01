/************************************************************************\
* (c) Copyright 2021 CERN for the benefit of the LHCb Collaboration      *
\************************************************************************/
#include "LowOccupancy.cuh"

void low_occupancy::low_occupancy_t::set_arguments_size(
  ArgumentReferences<Parameters> arguments,
  const RuntimeOptions&,
  const Constants&,
  const HostBuffers&) const
{

  set_size<dev_number_of_selected_events_t>(arguments, 1);
  set_size<host_number_of_selected_events_t>(arguments, 1);

  set_size<dev_event_list_output_t>(arguments, size<dev_event_list_t>(arguments));
  set_size<host_event_list_output_t>(arguments, size<dev_event_list_t>(arguments));
  set_size<dev_event_decisions_t>(arguments, size<dev_event_list_t>(arguments));

}

void low_occupancy::low_occupancy_t::operator()(
  const ArgumentReferences<Parameters>& arguments,
  const RuntimeOptions&,
  const Constants&,
  HostBuffers&,
  const Allen::Context& context) const
{

  initialize<host_event_list_output_t>(arguments, 0, context);
  initialize<dev_event_list_output_t>(arguments, 0, context);
  initialize<dev_event_decisions_t>(arguments, 0, context);
  initialize<dev_number_of_selected_events_t>(arguments, 0, context);

  global_function(low_occupancy)(dim3(size<dev_event_list_t>(arguments)), property<block_dim_t>(), context)(arguments);

  copy<host_number_of_selected_events_t, dev_number_of_selected_events_t>(arguments, context);
  Allen::synchronize(context);

  reduce_size<dev_event_list_output_t>(arguments, first<host_number_of_selected_events_t>(arguments));
  copy<host_event_list_output_t, dev_event_list_output_t>(arguments, context);
  Allen::synchronize(context);
  reduce_size<host_event_list_output_t>(arguments, first<host_number_of_selected_events_t>(arguments));

}

__global__ void low_occupancy::low_occupancy(low_occupancy::Parameters parameters)
{

  const auto event_number = parameters.dev_event_list[blockIdx.x];
  Velo::Consolidated::ConstTracks velo_tracks {parameters.dev_offsets_velo_tracks,
                                               parameters.dev_offsets_velo_track_hit_number,
                                               event_number,
                                               parameters.dev_number_of_events[0]};
  const unsigned number_of_velo_tracks = velo_tracks.number_of_tracks(event_number);

  unsigned* event_decision = parameters.dev_event_decisions.get() + blockIdx.x;
  const bool dec = number_of_velo_tracks >= parameters.minTracks && number_of_velo_tracks < parameters.maxTracks;
  if (dec) atomicOr( event_decision, dec );

  if ( threadIdx.x == 0 && *event_decision ) {
    const auto current_event = atomicAdd(parameters.dev_number_of_selected_events.get(), 1);
    parameters.dev_event_list_output[current_event] = event_number;
  }
}
