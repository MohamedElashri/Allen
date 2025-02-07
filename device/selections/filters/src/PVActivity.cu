/************************************************************************\
* (c) Copyright 2022 CERN for the benefit of the LHCb Collaboration      *
*                                                                             *
* This software is distributed under the terms of the Apache License          *
* version 2 (Apache-2.0), copied verbatim in the file "LICENSE".              *
*                                                                             *
* In applying this licence, CERN does not waive the privileges and immunities *
* granted to it by virtue of its status as an Intergovernmental Organization  *
* or submit itself to any jurisdiction.                                       *
\************************************************************************/
#include "PVActivity.cuh"

INSTANTIATE_ALGORITHM(pv_activity_filter::pv_activity_filter_t)

void pv_activity_filter::pv_activity_filter_t::set_arguments_size(
  ArgumentReferences<Parameters> arguments,
  const RuntimeOptions&,
  const Constants&) const
{
  set_size<dev_number_of_selected_events_t>(arguments, 1);
  set_size<host_number_of_selected_events_t>(arguments, 1);
  set_size<dev_event_list_output_t>(arguments, size<dev_event_list_t>(arguments));
}

void pv_activity_filter::pv_activity_filter_t::operator()(
  const ArgumentReferences<Parameters>& arguments,
  const RuntimeOptions&,
  const Constants&,
  const Allen::Context& context) const
{
  Allen::memset_async<dev_number_of_selected_events_t>(arguments, 0, context);
  Allen::memset_async<host_number_of_selected_events_t>(arguments, 0, context);
  Allen::memset_async<dev_event_list_output_t>(arguments, 0, context);

  global_function(pv_activity_filter)(dim3(1), dim3(m_block_dim_x), context)(
    arguments, size<dev_event_list_t>(arguments), m_minPVs, m_maxPVs);

  Allen::copy<host_number_of_selected_events_t, dev_number_of_selected_events_t>(arguments, context);
  reduce_size<dev_event_list_output_t>(arguments, first<host_number_of_selected_events_t>(arguments));
}

__global__ void pv_activity_filter::pv_activity_filter(
  pv_activity_filter::Parameters parameters,
  const unsigned number_of_events,
  const unsigned minPVs,
  const unsigned maxPVs)
{

  for (unsigned idx = threadIdx.x; idx < number_of_events; idx += blockDim.x) {
    auto event_number = parameters.dev_event_list[idx];
    const auto number_of_pvs_event = parameters.dev_number_of_multi_final_vertices[event_number];
    const bool decision = number_of_pvs_event >= minPVs && number_of_pvs_event < maxPVs;

    if (decision) {
      const auto current_event = atomicAdd(parameters.dev_number_of_selected_events.data(), 1);
      parameters.dev_event_list_output[current_event] = mask_t {event_number};
    }
  }
}
