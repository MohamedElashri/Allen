/************************************************************************\
* (c) Copyright 2021 CERN for the benefit of the LHCb Collaboration      *
\************************************************************************/
#include "ODINBeamCrossingType.cuh"
#include "Event/ODIN.h"
#include "ODINBank.cuh"

INSTANTIATE_ALGORITHM( odin_beamcrossingtype::odin_beamcrossingtype_t)

void odin_beamcrossingtype::odin_beamcrossingtype_t::set_arguments_size(
  ArgumentReferences<Parameters> arguments,
  const RuntimeOptions&,
  const Constants&,
  const HostBuffers&) const
{
  set_size<dev_number_of_selected_events_t>(arguments, 1);
  set_size<host_number_of_selected_events_t>(arguments, 1);
  set_size<dev_event_list_output_t>(arguments, size<dev_event_list_t>(arguments));
}


template<bool mep_layout>
__global__ void odin_beamcrossingtype_kernel(
  odin_beamcrossingtype::Parameters parameters,
  const unsigned number_of_events)
{

  for (unsigned idx = threadIdx.x; idx < number_of_events; idx += blockDim.x) {
    const unsigned event_number = parameters.dev_event_list[idx];

    [[maybe_unused]] const unsigned* event_odin_data = nullptr;
    if constexpr ( mep_layout ) {
      event_odin_data =
	odin_data_mep_t::data(parameters.dev_odin_raw_input, parameters.dev_odin_raw_input_offsets, event_number);
    }
    else {
      event_odin_data =
	odin_data_t::data(parameters.dev_odin_raw_input, parameters.dev_odin_raw_input_offsets, event_number);
    }


    const unsigned bxt = static_cast<unsigned int>(LHCb::ODIN({event_odin_data, 10}).bunchCrossingType());
    if (bxt == parameters.beam_crossing_type) {
      const auto current_event = atomicAdd(parameters.dev_number_of_selected_events.get(), 1);
      parameters.dev_event_list_output[current_event] = mask_t {event_number};
    }
  }
}


void odin_beamcrossingtype::odin_beamcrossingtype_t::operator()(
  const ArgumentReferences<Parameters>& arguments,
  const RuntimeOptions& runtime_options,
  const Constants&,
  HostBuffers&,
  const Allen::Context& context) const
{
  initialize<dev_number_of_selected_events_t>(arguments, 0, context);
  initialize<host_number_of_selected_events_t>(arguments, 0, context);
  initialize<dev_event_list_output_t>(arguments, 0, context);

  global_function( runtime_options.mep_layout ? odin_beamcrossingtype_kernel<true> : odin_beamcrossingtype_kernel<false> )(dim3(1), 
													     dim3(property<block_dim_x_t>().get()), context)(
    arguments, size<dev_event_list_t>(arguments));

  Allen::
    copy<host_number_of_selected_events_t, dev_number_of_selected_events_t>(
      arguments, context);
  reduce_size<dev_event_list_output_t>(
    arguments, first<host_number_of_selected_events_t>(arguments));
}
