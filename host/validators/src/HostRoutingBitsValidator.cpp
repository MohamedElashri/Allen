/*****************************************************************************\
* (c) Copyright 2020 CERN for the benefit of the LHCb Collaboration           *
*                                                                             *
* This software is distributed under the terms of the Apache License          *
* version 2 (Apache-2.0), copied verbatim in the file "LICENSE".              *
*                                                                             *
* In applying this licence, CERN does not waive the privileges and immunities *
* granted to it by virtue of its status as an Intergovernmental Organization  *
* or submit itself to any jurisdiction.                                       *
\*****************************************************************************/
#include "HostRoutingBitsValidator.h"
#include "RoutingBitsChecker.h"

INSTANTIATE_ALGORITHM(host_routingbits_validator::host_routingbits_validator_t)

void host_routingbits_validator::host_routingbits_validator_t::operator()(
  const ArgumentReferences<Parameters>& arguments,
  const RuntimeOptions& runtime_options,
  const Constants&,
  const Allen::Context&) const
{
  if (runtime_options.checker_invoker == nullptr) return;

  const auto map = m_routingbit_map.value();

  auto& checker = runtime_options.checker_invoker->checker<RoutingBitsChecker>(name());
  host_function([&checker](host_routingbits_validator::Parameters parameters) {
    checker.accumulate(parameters.host_routingbits, parameters.host_number_of_events[0]);
  })(arguments);
}
