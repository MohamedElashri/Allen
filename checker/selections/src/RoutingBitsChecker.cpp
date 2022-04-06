/*****************************************************************************\
* (c) Copyright 2018-2020 CERN for the benefit of the LHCb Collaboration      *
\*****************************************************************************/
#include "RoutingBitsChecker.h"
#include "ProgramOptions.h"
#include "HltDecReport.cuh"
#include <regex>

void RoutingBitsChecker::accumulate(
  const char* line_names,
  const unsigned* dec_reports,
  const unsigned* routing_bits,
  const unsigned number_of_events,
  const std::map<std::string, uint32_t> rb_map)
{
  for (auto i = 0u; i < number_of_events; ++i) {
    auto const* rbs = routing_bits + 4 * i;
    debug_cout << "After copying to the host, event n. " << i << ", routing bits ";
    for (auto j = 0u; j < 4; ++j) {
      uint32_t rb = rbs[j];
      debug_cout << "  " << rb;
    }
    debug_cout << std::endl;
  }
}

void RoutingBitsChecker::report(size_t) const
{

  // check that all lines, whether fired or not, correspond to at least one routing bit
  for (auto line_name : m_line_names) {
    bool line_found = false;
    std::vector<int> set_rbs;
    for (auto const& [expr, bit] : m_rb_map) {
      std::regex rb_regex(expr);
      if (std::regex_match(line_name, rb_regex)) {
        line_found = true;
        set_rbs.push_back(bit);
      }
    }
    debug_cout << "Line " << line_name << " sets bits ";
    std::for_each(set_rbs.begin(), set_rbs.end(), [](const auto& elem) { debug_cout << elem << " "; });
    debug_cout << std::endl;
    if (!line_found) {
      std::cout
        << "Line " << line_name
        << "  doesn't correspond to a bit in the routing bit map. Please set it in either "
           "host/routing_bits/include/RoutingBitsDefinition.h or in configuration/python/AllenConf/persistency.py "
        << std::endl;
    }
  }
}
