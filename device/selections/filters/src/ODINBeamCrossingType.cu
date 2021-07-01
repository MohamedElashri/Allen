/************************************************************************\
* (c) Copyright 2021 CERN for the benefit of the LHCb Collaboration      *
\************************************************************************/
#include "ODINBeamCrossingType.cuh"
#include "Event/ODIN.h"
#include "ODINBank.cuh"

void odin_beamcrossingtype::odin_beamcrossingtype_t::set_arguments_size(
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

void odin_beamcrossingtype::odin_beamcrossingtype_t::operator()(
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

  global_function(odin_beamcrossingtype)(dim3(size<dev_event_list_t>(arguments)), property<block_dim_t>(), context)(arguments);

  copy<host_number_of_selected_events_t, dev_number_of_selected_events_t>(arguments, context);
  Allen::synchronize(context);

  reduce_size<dev_event_list_output_t>(arguments, first<host_number_of_selected_events_t>(arguments));
  copy<host_event_list_output_t, dev_event_list_output_t>(arguments, context);
  Allen::synchronize(context);
  reduce_size<host_event_list_output_t>(arguments, first<host_number_of_selected_events_t>(arguments));
}

__global__ void odin_beamcrossingtype::odin_beamcrossingtype(odin_beamcrossingtype::Parameters parameters)
{

  const auto event_number = parameters.dev_event_list[blockIdx.x];
  const unsigned* event_odin_data = nullptr;
  if (parameters.dev_mep_layout[0]) {
    event_odin_data =
      odin_data_mep_t::data(parameters.dev_odin_raw_input, parameters.dev_odin_raw_input_offsets, event_number);
  }
  else {
    event_odin_data =
      odin_data_t::data(parameters.dev_odin_raw_input, parameters.dev_odin_raw_input_offsets, event_number);
  }

  const uint32_t word8 = event_odin_data [LHCb::ODIN::Data::Word8];
  const unsigned bxt = (word8 & LHCb::ODIN::BXTypeMask) >> LHCb::ODIN::BXTypeBits;

  unsigned* event_decision = parameters.dev_event_decisions.get() + blockIdx.x;
  const bool dec = bxt == parameters.beam_crossing_type;
  if (dec) atomicOr( event_decision, dec );

  if ( threadIdx.x == 0 && *event_decision ) {
    const auto current_event = atomicAdd(parameters.dev_number_of_selected_events.get(), 1);
    parameters.dev_event_list_output[current_event] = event_number;
  }
}
