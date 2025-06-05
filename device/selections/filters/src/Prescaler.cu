/************************************************************************\
* (c) Copyright 2024 CERN for the benefit of the LHCb Collaboration      *
*                                                                             *
* This software is distributed under the terms of the Apache License          *
* version 2 (Apache-2.0), copied verbatim in the file "LICENSE".              *
*                                                                             *
* In applying this licence, CERN does not waive the privileges and immunities *
* granted to it by virtue of its status as an Intergovernmental Organization  *
* or submit itself to any jurisdiction.                                       *
\************************************************************************/
#include "Prescaler.cuh"
#include "Event/ODIN.h"
#include "DeterministicScaler.cuh"

INSTANTIATE_ALGORITHM(prescaler::prescaler_t)

void prescaler::prescaler_t::init()
{
  if (m_pre_scaler_hash_string.value().empty()) {
    throw HashNotPopulatedException(name());
  }

  m_pre_scaler_hash = mixString(m_pre_scaler_hash_string.value().size(), m_pre_scaler_hash_string.value());
}

void prescaler::prescaler_t::set_arguments_size(
  ArgumentReferences<Parameters> arguments,
  const RuntimeOptions&,
  const Constants&) const
{
  set_size<dev_number_of_selected_events_t>(arguments, 1);
  set_size<host_number_of_selected_events_t>(arguments, 1);
  set_size<dev_event_list_output_t>(arguments, size<dev_event_list_t>(arguments));
}

__global__ void prescaler_kernel(
  prescaler::Parameters parameters,
  const unsigned number_of_events,
  uint32_t pre_scaler_hash,
  float pre_scaler)
{
  for (unsigned idx = threadIdx.x; idx < number_of_events; idx += blockDim.x) {
    const unsigned event_number = parameters.dev_event_list[idx];
    LHCb::ODIN odin {parameters.dev_odin_data[event_number]};

    const uint32_t run_no = odin.runNumber();
    const uint32_t evt_hi = static_cast<uint32_t>(odin.eventNumber() >> 32);
    const uint32_t evt_lo = static_cast<uint32_t>(odin.eventNumber() & 0xffffffff);
    const uint32_t gps_hi = static_cast<uint32_t>(odin.gpsTime() >> 32);
    const uint32_t gps_lo = static_cast<uint32_t>(odin.gpsTime() & 0xffffffff);

    if (deterministic_scaler(pre_scaler_hash, pre_scaler, run_no, evt_hi, evt_lo, gps_hi, gps_lo)) {
      const auto current_event = atomicAdd(parameters.dev_number_of_selected_events.data(), 1);
      parameters.dev_event_list_output[current_event] = mask_t {event_number};
    }
  }
}

void prescaler::prescaler_t::operator()(
  const ArgumentReferences<Parameters>& arguments,
  const RuntimeOptions&,
  const Constants&,
  const Allen::Context& context) const
{
  Allen::memset_async<dev_number_of_selected_events_t>(arguments, 0, context);
  Allen::memset_async<host_number_of_selected_events_t>(arguments, 0, context);
  Allen::memset_async<dev_event_list_output_t>(arguments, 0, context);

  global_function(prescaler_kernel)(dim3(1), dim3(m_block_dim_x), context)(
    arguments, size<dev_event_list_t>(arguments), m_pre_scaler_hash, m_pre_scaler);

  Allen::copy<host_number_of_selected_events_t, dev_number_of_selected_events_t>(arguments, context);
  reduce_size<dev_event_list_output_t>(arguments, first<host_number_of_selected_events_t>(arguments));
}
