/*****************************************************************************\
* (c) Copyright 2023 CERN for the benefit of the LHCb Collaboration           *
*                                                                             *
* This software is distributed under the terms of the Apache License          *
* version 2 (Apache-2.0), copied verbatim in the file "COPYING".              *
*                                                                             *
* In applying this licence, CERN does not waive the privileges and immunities *
* granted to it by virtue of its status as an Intergovernmental Organization  *
* or submit itself to any jurisdiction.                                       *
\*****************************************************************************/
#include "CheckECALEnergy.cuh"

INSTANTIATE_ALGORITHM(check_ecal_energy::check_ecal_energy_t)

void check_ecal_energy::check_ecal_energy_t::set_arguments_size(
  ArgumentReferences<Parameters> arguments,
  const RuntimeOptions&,
  const Constants&) const
{
  set_size<dev_number_of_selected_events_t>(arguments, 1);
  set_size<host_number_of_selected_events_t>(arguments, 1);
  set_size<dev_event_list_output_t>(arguments, size<dev_event_list_t>(arguments));
}

void check_ecal_energy::check_ecal_energy_t::operator()(
  const ArgumentReferences<Parameters>& arguments,
  const RuntimeOptions&,
  const Constants&,
  const Allen::Context& context) const
{
  Allen::memset_async<dev_number_of_selected_events_t>(arguments, 0, context);
  Allen::memset_async<host_number_of_selected_events_t>(arguments, 0, context);
  Allen::memset_async<dev_event_list_output_t>(arguments, 0, context);

  global_function(check_ecal_energy)(dim3(1), m_block_dim, context)(
    arguments, size<dev_event_list_t>(arguments), m_ecalCut, m_cutHigh.value());

  Allen::copy<host_number_of_selected_events_t, dev_number_of_selected_events_t>(arguments, context);
  reduce_size<dev_event_list_output_t>(arguments, first<host_number_of_selected_events_t>(arguments));
}

__global__ void check_ecal_energy::check_ecal_energy(
  check_ecal_energy::Parameters parameters,
  const unsigned number_of_events,
  const float ecalCut,
  const bool cutHigh)
{
  for (unsigned event_idx = blockIdx.x * blockDim.x + threadIdx.x; event_idx < number_of_events;
       event_idx += blockDim.x * gridDim.x) {
    const auto event_number = parameters.dev_event_list[event_idx];
    const float ecal_energy = parameters.dev_total_ecal_e[event_number];
    unsigned decision = cutHigh ? ecal_energy < ecalCut : ecal_energy > ecalCut;
    if (decision) {
      const auto current_event = atomicAdd(parameters.dev_number_of_selected_events.data(), 1);
      parameters.dev_event_list_output[current_event] = mask_t {event_number};
    }
  }
}