/*****************************************************************************\
* (c) Copyright 2020 CERN for the benefit of the LHCb Collaboration           *
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

  const auto map = m_routingbit_map.get_value().get();

  auto& checker = runtime_options.checker_invoker->checker<RoutingBitsChecker>(name());
  host_function([&checker](host_routingbits_validator::Parameters parameters) {
    checker.accumulate(parameters.host_routingbits, parameters.host_number_of_events[0]);
  })(arguments);
}
