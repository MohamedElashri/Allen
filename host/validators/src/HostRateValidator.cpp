/*****************************************************************************\
* (c) Copyright 2020 CERN for the benefit of the LHCb Collaboration           *
\*****************************************************************************/
#include "HostRateValidator.h"
#include "RateChecker.h"

void host_rate_validator::host_rate_validator_t::operator()(
  const ArgumentReferences<Parameters>& arguments,
  const RuntimeOptions& runtime_options,
  const Constants&,
  HostBuffers&,
  const Allen::Context&) const
{
  const auto selections = make_vector<dev_selections_t>(arguments);
  const auto selections_offsets = make_vector<dev_selections_offsets_t>(arguments);
  const char* line_names_char = data<host_names_of_lines_t>(arguments);
  const std::string line_names_str = line_names_char;

  std::vector<std::string> line_names;
  std::stringstream data(line_names_str);
  std::string line_name;
  while (std::getline(data, line_name, ',')) {
    line_names.push_back(line_name);
  }

  auto& checker = runtime_options.checker_invoker->checker<RateChecker>(name());
  checker.accumulate(
    line_names,
    selections,
    selections_offsets,
    first<host_number_of_events_t>(arguments));
}
