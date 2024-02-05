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
#include "HostRateValidator.h"
#include "RateChecker.h"

INSTANTIATE_ALGORITHM(host_rate_validator::host_rate_validator_t)

void host_rate_validator::host_rate_validator_t::operator()(
  const ArgumentReferences<Parameters>& arguments,
  const RuntimeOptions& runtime_options,
  const Constants&,
  const Allen::Context&) const
{
  if (runtime_options.checker_invoker == nullptr) return;

  auto& checker = runtime_options.checker_invoker->checker<RateChecker>(name());
  host_function([&checker](host_rate_validator::Parameters parameters) {
    checker.accumulate(
      static_cast<char const*>(parameters.host_names_of_lines),
      parameters.host_dec_reports.get(),
      parameters.host_number_of_events[0]);
  })(arguments);
}
