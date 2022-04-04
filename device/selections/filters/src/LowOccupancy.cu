/************************************************************************\
* (c) Copyright 2022 CERN for the benefit of the LHCb Collaboration      *
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

  initialize<dev_number_of_selected_events_t>(arguments, 0, context);
  initialize<host_number_of_selected_events_t>(arguments, 0, context);
  initialize<dev_event_list_output_t>(arguments, 0, context);


  global_function(low_occupancy)(dim3(1), dim3(property<block_dim_x_t>().get()), context)(arguments, 
											  size<dev_event_list_t>(arguments));
  Allen::
    copy<host_number_of_selected_events_t, dev_number_of_selected_events_t>(
      arguments, context);
  reduce_size<dev_event_list_output_t>(
    arguments, first<host_number_of_selected_events_t>(arguments));
}

__global__ void low_occupancy::low_occupancy(low_occupancy::Parameters parameters, 
					     const unsigned number_of_events )
{ 

  for (unsigned idx = threadIdx.x; idx < number_of_events; idx += blockDim.x) {
    
    auto event_number = parameters.dev_event_list[idx];
    Velo::Consolidated::ConstTracks velo_tracks {parameters.dev_offsets_velo_tracks,
	parameters.dev_offsets_velo_track_hit_number,
	event_number,
	number_of_events};
    const unsigned number_of_velo_tracks = velo_tracks.number_of_tracks(event_number);

    if ( number_of_velo_tracks >= parameters.minTracks && number_of_velo_tracks < parameters.maxTracks ) {
      const auto current_event = atomicAdd(parameters.dev_number_of_selected_events.get(), 1);
      parameters.dev_event_list_output[current_event] = mask_t{event_number};
    }
  }
}
