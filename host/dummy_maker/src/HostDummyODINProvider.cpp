/*****************************************************************************\
* (c) Copyright 2021 CERN for the benefit of the LHCb Collaboration           *
*                                                                             *
* This software is distributed under the terms of the Apache License          *
* version 2 (Apache-2.0), copied verbatim in the file "COPYING".              *
*                                                                             *
* In applying this licence, CERN does not waive the privileges and immunities *
* granted to it by virtue of its status as an Intergovernmental Organization  *
* or submit itself to any jurisdiction.                                       *
\*****************************************************************************/
#include "HostDummyODINProvider.h"

#include "DeterministicScaler.cuh"

INSTANTIATE_ALGORITHM(host_dummy_odin_provider::host_dummy_odin_provider_t)

void host_dummy_odin_provider::host_dummy_odin_provider_t::set_arguments_size(
  ArgumentReferences<Parameters> arguments,
  const RuntimeOptions&,
  const Constants&) const
{
  set_size<dev_odin_dummy_t>(arguments, first<host_number_of_events_t>(arguments));
  set_size<host_odin_dummy_t>(arguments, first<host_number_of_events_t>(arguments));
}

void host_dummy_odin_provider::host_dummy_odin_provider_t::operator()(
  const ArgumentReferences<Parameters>& arguments,
  const RuntimeOptions&,
  const Constants&,
  const Allen::Context& context) const
{
  auto name_hash = mixString(sizeof(name()), name());

  for (unsigned event_number = 0; event_number < first<host_number_of_events_t>(arguments); ++event_number) {
    auto odin_dummy = LHCb::ODIN {data<host_odin_data_t>(arguments)[event_number]};
    unsigned event_type = 0u;
    auto bx_type = static_cast<std::uint8_t>(odin_dummy.bunchCrossingType());
    const uint32_t run_no = odin_dummy.runNumber();
    const uint32_t evt_hi = static_cast<uint32_t>(odin_dummy.eventNumber() >> 32);
    const uint32_t evt_lo = static_cast<uint32_t>(odin_dummy.eventNumber() & 0xffffffff);
    const uint32_t gps_hi = static_cast<uint32_t>(odin_dummy.gpsTime() >> 32);
    const uint32_t gps_lo = static_cast<uint32_t>(odin_dummy.gpsTime() & 0xffffffff);

    if (deterministic_scaler(name_hash, m_lumi_frac.get_value().get()[bx_type], run_no, evt_hi, evt_lo, gps_hi, gps_lo))
      event_type = static_cast<unsigned>(LHCb::ODIN::EventTypes::Lumi);

    odin_dummy.setEventType(event_type);
    auto* output = data<host_odin_dummy_t>(arguments) + event_number;
    std::copy_n(odin_dummy.data.data(), odin_dummy.data.size(), output->data());
  }

  Allen::copy_async<dev_odin_dummy_t, host_odin_dummy_t>(arguments, context);
}
