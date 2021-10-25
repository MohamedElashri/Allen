/*****************************************************************************\
* (c) Copyright 2018-2020 CERN for the benefit of the LHCb Collaboration      *
\*****************************************************************************/
#include "RoutingBitsChecker.h"
#include "ProgramOptions.h"
#include "HltDecReport.cuh"

void RoutingBitsChecker::accumulate(
  const char* line_names,
  const unsigned* dec_reports,
  const unsigned* routing_bits,
  const unsigned number_of_events)
{
  std::lock_guard<std::mutex> guard(m_mutex);
  if (!m_counters.size()) {
    m_line_names = split_string(line_names, ",");
    m_counters = std::vector<unsigned>(m_line_names.size(), 0);
  }
  const auto number_of_lines = m_line_names.size();

  for (auto i = 0u; i < number_of_events; ++i) {
    bool any_line_fired = false;
    auto const* decs = dec_reports + (2 + number_of_lines) * i;
    auto const* rbs = routing_bits + 2 * i;
    for (auto j = 0u; j < 2; ++j) {
      uint32_t rb = rbs[j];
      debug_cout << "Event n. " << i << ", routing bits checker word " << j << "  " << rb << std::endl;
    }
    for (auto j = 0u; j < number_of_lines; ++j) {
      HltDecReport dec_report(decs[2 + j]);
      if (dec_report.decision()) {
        ++m_counters[j];
        any_line_fired = true;
      }
    }
    if (any_line_fired) {
      ++m_tot;
    }
  }
}

void RoutingBitsChecker::report(const size_t requested_events) const {}
