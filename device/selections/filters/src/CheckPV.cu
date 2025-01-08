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
#include "CheckPV.cuh"

INSTANTIATE_ALGORITHM(check_pvs::check_pvs_t)

void check_pvs::check_pvs_t::set_arguments_size(
  ArgumentReferences<Parameters> arguments,
  const RuntimeOptions&,
  const Constants&) const
{
  set_size<dev_number_of_selected_events_t>(arguments, 1);
  set_size<host_number_of_selected_events_t>(arguments, 1);
  set_size<dev_event_list_output_t>(arguments, size<dev_event_list_t>(arguments));
}

void check_pvs::check_pvs_t::operator()(
  const ArgumentReferences<Parameters>& arguments,
  const RuntimeOptions&,
  const Constants&,
  const Allen::Context& context) const
{
  Allen::memset_async<dev_number_of_selected_events_t>(arguments, 0, context);
  Allen::memset_async<host_number_of_selected_events_t>(arguments, 0, context);
  Allen::memset_async<dev_event_list_output_t>(arguments, 0, context);

  global_function(check_pvs)(dim3(size<dev_event_list_t>(arguments)), m_block_dim, context)(arguments, m_minZ, m_maxZ);

  Allen::copy<host_number_of_selected_events_t, dev_number_of_selected_events_t>(arguments, context);
  reduce_size<dev_event_list_output_t>(arguments, first<host_number_of_selected_events_t>(arguments));
}

__global__ void check_pvs::check_pvs(check_pvs::Parameters parameters, const float minZ, const float maxZ)
{

  const unsigned event_number = parameters.dev_event_list[blockIdx.x];
  const PV::Vertex* vertices = parameters.dev_multi_final_vertices + event_number * PV::max_number_vertices;

  __shared__ unsigned event_decision;
  if (threadIdx.x == 0) event_decision = 0;
  __syncthreads();

  for (unsigned i = threadIdx.x; i < parameters.dev_number_of_multi_final_vertices[event_number]; i += blockDim.x) {
    const auto& pv = vertices[i];
    const bool dec = pv.position.z >= minZ and pv.position.z < maxZ;
    if (dec) atomicOr(&event_decision, dec);
  }

  __syncthreads();

  if (threadIdx.x == 0 && event_decision) {
    const auto current_event = atomicAdd(parameters.dev_number_of_selected_events.data(), 1);
    parameters.dev_event_list_output[current_event] = mask_t {event_number};
  }
}
