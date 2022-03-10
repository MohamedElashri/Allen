/*****************************************************************************\
* (c) Copyright 2018-2020 CERN for the benefit of the LHCb Collaboration      *
\*****************************************************************************/
#include "RoutingBitsChecker.h"
#include "ProgramOptions.h"
#include "HltDecReport.cuh"
#include "boost/regex.hpp"

void RoutingBitsChecker::accumulate(
  const char* line_names,
  const unsigned* dec_reports,
  const unsigned* routing_bits,
  const unsigned number_of_events,
  const std::map<uint32_t, std::string> rb_map)
{
  std::lock_guard<std::mutex> guard(m_mutex);
  m_rb_map = rb_map;
  if (!m_counters.size()) {
    m_line_names = split_string(line_names, ",");
    m_counters = std::vector<unsigned>(m_line_names.size(), 0);
  }
  const auto number_of_lines = m_line_names.size();

  // for (auto i = 0u; i < number_of_events; ++i) {
  //  bool any_line_fired = false;
  //  auto const* decs = dec_reports + (2 + number_of_lines) * i;
  //  auto const* rbs = routing_bits + 4 * i;
  //  for (auto j = 0u; j < 4; ++j) {
  //    uint32_t rb = rbs[j];
  //    debug_cout << "Event n. " << i << ", routing bits checker word " << j << "  " << rb << std::endl;
  //  }
  //  for (auto j = 0u; j < number_of_lines; ++j) {
  //    HltDecReport dec_report(decs[2 + j]);
  //    if (dec_report.decision()) {
  //      ++m_counters[j];
  //      any_line_fired = true;
  //    }
  //  }
  //  if (any_line_fired) {
  //    ++m_tot;
  //  }
  //}
}

void RoutingBitsChecker::report(size_t) const
{

  // check that all lines, whether fired or not, correspond to at least one routing bit
  for (auto line_name : m_line_names) {
    bool line_found = false;
    std::vector<int> set_rbs;
    for (auto const& [bit, expr] : m_rb_map) {
      boost::regex rb_regex(expr);
      if (boost::regex_match(line_name, rb_regex)) {
        line_found = true;
        set_rbs.push_back(bit);
      }
    }
    debug_cout << "Line " << line_name << " sets bits ";
    std::for_each(set_rbs.begin(), set_rbs.end(), [](const auto& elem) { debug_cout << elem << " "; });
    debug_cout << std::endl;
    if (!line_found) {
      error_cout
        << "Line " << line_name
        << "  doesn't correspond to a bit in the routing bit map. Please set it in either "
           "host/routing_bits/include/RoutingBitsDefinition.h or in configuration/python/AllenConf/persistency.py "
        << std::endl;
    }
  }
  error_cout << std::endl;
}
