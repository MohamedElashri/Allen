/**************************************************************************** \
* (c) Copyright 2024 CERN for the benefit of the LHCb Collaboration           *
*                                                                             *
* This software is distributed under the terms of the Apache License          *
* version 2 (Apache-2.0), copied verbatim in the file "LICENSE".              *
*                                                                             *
* In applying this licence, CERN does not waive the privileges and immunities *
* granted to it by virtue of its status as an Intergovernmental Organization  *
* or submit itself to any jurisdiction.                                       *
\*****************************************************************************/
#include "ODINOrbitNumber.cuh"
#include "Event/ODIN.h"
#include "ODINBank.cuh"

INSTANTIATE_ALGORITHM(odin_orbitnumber::odin_orbitnumber_t)

void odin_orbitnumber::odin_orbitnumber_t::set_arguments_size(
  ArgumentReferences<Parameters> arguments,
  const RuntimeOptions&,
  const Constants&) const
{
  set_size<dev_number_of_selected_events_t>(arguments, 1);
  set_size<host_number_of_selected_events_t>(arguments, 1);
  set_size<dev_event_list_output_t>(arguments, size<dev_event_list_t>(arguments));
}

__global__ void odin_orbitnumber_kernel(
  odin_orbitnumber::Parameters parameters,
  const unsigned number_of_events,
  const unsigned odin_orbit_modulo,
  const unsigned odin_orbit_remainder)
{

  for (unsigned idx = threadIdx.x; idx < number_of_events; idx += blockDim.x) {
    const unsigned event_number = parameters.dev_event_list[idx];
    const unsigned orbit_number = LHCb::ODIN {parameters.dev_odin_data[event_number]}.orbitNumber();

    if (orbit_number % odin_orbit_modulo == odin_orbit_remainder) {
      const auto current_event = atomicAdd(parameters.dev_number_of_selected_events.data(), 1);
      parameters.dev_event_list_output[current_event] = mask_t {event_number};
    }
  }
}

void odin_orbitnumber::odin_orbitnumber_t::operator()(
  const ArgumentReferences<Parameters>& arguments,
  const RuntimeOptions&,
  const Constants&,
  const Allen::Context& context) const
{
  Allen::memset_async<dev_number_of_selected_events_t>(arguments, 0, context);
  Allen::memset_async<host_number_of_selected_events_t>(arguments, 0, context);
  Allen::memset_async<dev_event_list_output_t>(arguments, 0, context);

  global_function(odin_orbitnumber_kernel)(dim3(1), dim3(m_block_dim_x), context)(
    arguments, size<dev_event_list_t>(arguments), m_odin_orbit_modulo, m_odin_orbit_remainder);

  Allen::copy<host_number_of_selected_events_t, dev_number_of_selected_events_t>(arguments, context);
  reduce_size<dev_event_list_output_t>(arguments, first<host_number_of_selected_events_t>(arguments));
}
