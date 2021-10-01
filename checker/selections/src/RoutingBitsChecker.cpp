/*****************************************************************************\
* (c) Copyright 2018-2020 CERN for the benefit of the LHCb Collaboration      *
\*****************************************************************************/
#include "RoutingBitsChecker.h"
#include "ProgramOptions.h"
#include "HltDecReport.cuh"


void RoutingBitsChecker::accumulate(const char* line_names, const unsigned* dec_reports, const uint32_t* routing_bits, const unsigned number_of_events)
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
    auto const* rbs = routing_bits + i;
    uint32_t rb = rbs[i];
    //std::cout << "Event n. " << i << "  "  << rb << std::endl;
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

void RoutingBitsChecker::report(const size_t requested_events) const
{
  //// Assume 30 MHz input rate.
  //const double in_rate = 30000.0;
  //size_t longest_string = 10;
  //for (const auto& line_name : m_line_names) {
  //  if (line_name.length() > longest_string) {
  //    longest_string = line_name.length();
  //  }
  //}

  //for (unsigned i_line = 0; i_line < m_line_names.size(); i_line++) {
  //  std::printf("%s:", m_line_names[i_line].c_str());
  //  for (unsigned i = 0; i < longest_string - m_line_names[i_line].length(); ++i) {
  //    std::printf(" ");
  //  }

  //  std::printf(
  //    " %6i/%6lu, (%8.2f +/- %8.2f) kHz\n",
  //    m_counters[i_line],
  //    requested_events,
  //    1. * m_counters[i_line] / requested_events * in_rate,
  //    binomial_error(requested_events, m_counters[i_line]) * in_rate);
  //}

  //std::printf("Inclusive:");
  //for (unsigned i = 0; i < longest_string - 9; ++i) {
  //  std::printf(" ");
  //}

  //std::printf(
  //  " %6i/%6lu, (%8.2f +/- %8.2f) kHz\n",
  //  m_tot,
  //  requested_events,
  //  1. * m_tot / requested_events * in_rate,
  //  binomial_error(requested_events, m_tot) * in_rate);

  //std::printf("\n");
}
