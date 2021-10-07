/*****************************************************************************\
* (c) Copyright 2020 CERN for the benefit of the LHCb Collaboration           *
\*****************************************************************************/
#include "HostRateValidator.h"
#include "RateChecker.h"

INSTANTIATE_ALGORITHM(host_rate_validator::host_rate_validator_t)

void host_rate_validator::host_rate_validator_t::operator()(
  const ArgumentReferences<Parameters>& arguments,
  const RuntimeOptions& runtime_options,
  const Constants&,
  HostBuffers&,
  const Allen::Context&) const
{
  if (runtime_options.checker_invoker == nullptr) return;

  auto& checker = runtime_options.checker_invoker->checker<RateChecker>(name());
  host_function([&checker](host_rate_validator::Parameters parameters) {
    checker.accumulate(
      static_cast<char const*>(parameters.host_names_of_lines),
      parameters.host_dec_reports,
      parameters.host_number_of_events[0]);
  })(arguments);
}
