/*****************************************************************************\
* (c) Copyright 2022 CERN for the benefit of the LHCb Collaboration           *
*                                                                             *
* This software is distributed under the terms of the Apache License          *
* version 2 (Apache-2.0), copied verbatim in the file "COPYING".              *
*                                                                             *
* In applying this licence, CERN does not waive the privileges and immunities *
* granted to it by virtue of its status as an Intergovernmental Organization  *
* or submit itself to any jurisdiction.                                       *
\*****************************************************************************/
#ifndef ALLEN_STANDALONE

#include "GatherSelections.cuh"
#include "SelectionsEventModel.cuh"
#include "Gaudi/Accumulators.h"
#include "Gaudi/Accumulators/Histogram.h"

template<int I>
using gaudi_histo_t = Gaudi::Accumulators::Histogram<I, Gaudi::Accumulators::atomicity::full, float>;

void gather_selections::gather_selections_t::init_monitor()
{
  const auto line_names = std::string(property<names_of_active_lines_t>());
  std::istringstream is(line_names);
  std::string line_name;
  std::vector<std::string> line_labels;
  while (std::getline(is, line_name, ',')) {
    const std::string pass_counter_name {line_name + "Pass"};
    const std::string rate_counter_name {line_name + "Rate"};
    const std::string rate_hist_name {line_name + "RateVsTime"};
    m_pass_counters.push_back(std::make_unique<Gaudi::Accumulators::Counter<>>(this, pass_counter_name));
    m_rate_counters.push_back(std::make_unique<Gaudi::Accumulators::Counter<>>(this, rate_counter_name));
    histograms_rates_vs_time.emplace_back((void*) new gaudi_histo_t<1>(
      this, rate_hist_name, rate_hist_name, Gaudi::Accumulators::Axis<float> {100, 0, 1000.}));
    line_labels.push_back(line_name);
  }
  unsigned int n_lines = line_labels.size();

  histogram_line_passes = (void*) new gaudi_histo_t<1>(
    this,
    "line_passes",
    "line passes",
    Gaudi::Accumulators::Axis<float> {n_lines, 0, (float) n_lines, {}, line_labels});
  histogram_line_rates = (void*) new gaudi_histo_t<1>(
    this, "line_rates", "line rates", Gaudi::Accumulators::Axis<float> {n_lines, 0, (float) n_lines, {}, line_labels});
}

void gather_selections::gather_selections_t::monitor_operator(
  const ArgumentReferences<Parameters>& arguments,
  Selections::ConstSelections& sels) const
{
  auto* histogram_line_passes_p = reinterpret_cast<gaudi_histo_t<1>*>(histogram_line_passes);
  auto hist_buf = histogram_line_passes_p->buffer();
  // Fill non-postscaled counters and histograms
  for (auto j = 0u; j < first<host_number_of_active_lines_t>(arguments); ++j) {
    auto buf = m_pass_counters[j]->buffer();
    for (auto i = 0u; i < first<host_number_of_events_t>(arguments); ++i) {
      auto decs = sels.get_span(j, i);
      for (auto k = 0u; k < decs.size(); ++k) {
        if (decs[k]) {
          ++buf;
          ++hist_buf[j];
          break;
        }
      }
    }
  }
}

void gather_selections::gather_selections_t::monitor_postscaled_operator(
  const ArgumentReferences<Parameters>& arguments,
  const Constants& constants,
  Selections::ConstSelections& sels) const
{
  auto* histogram_line_rates_p = reinterpret_cast<gaudi_histo_t<1>*>(histogram_line_rates);
  auto hist_buf = histogram_line_rates_p->buffer();
  auto time_bin = (std::chrono::duration_cast<std::chrono::duration<float>>(
                     std::chrono::high_resolution_clock::now() - constants.histogram_time_epoch))
                    .count() /
                  10.f;
  // Fill postscaled counters and histograms
  for (auto j = 0u; j < first<host_number_of_active_lines_t>(arguments); ++j) {
    auto buf = m_rate_counters[j]->buffer();
    auto* histograms_rates_vs_time_p = reinterpret_cast<gaudi_histo_t<1>*>(histograms_rates_vs_time[j]);
    auto buf_time = histograms_rates_vs_time_p->buffer();
    for (auto i = 0u; i < first<host_number_of_events_t>(arguments); ++i) {
      auto decs = sels.get_span(j, i);
      for (auto k = 0u; k < decs.size(); ++k) {
        if (decs[k]) {
          ++buf;
          ++buf_time[time_bin];
          ++hist_buf[j];
          break;
        }
      }
    }
  }
}

#endif
