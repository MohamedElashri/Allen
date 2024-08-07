/*****************************************************************************\
* (c) Copyright 2018-2020 CERN for the benefit of the LHCb Collaboration      *
*                                                                             *
* This software is distributed under the terms of the Apache License          *
* version 2 (Apache-2.0), copied verbatim in the file "LICENSE".              *
*                                                                             *
* In applying this licence, CERN does not waive the privileges and immunities *
* granted to it by virtue of its status as an Intergovernmental Organization  *
* or submit itself to any jurisdiction.                                       *
\*****************************************************************************/

#include "AverageChecker.h"

AverageChecker::AverageChecker(CheckerInvoker const*, std::string const&, std::string const& name) : m_name(name) {}

void AverageChecker::accumulate(FillFunc_t const& fill)
{
  // Multithread guard
  std::scoped_lock guard(m_mutex);
  fill(m_counters);
}

void AverageChecker::report(size_t n_events) const
{
  printf("%s: %lu events have been processed\n", m_name.c_str(), n_events);
  printf("%s: %lu counters are registered\n", m_name.c_str(), m_counters.size());
  for (const auto& [label, counter] : m_counters) {
    printf(
      "%s: mean = %0.6e, std = %0.6e, min = %0.6e, max = %0.6e\n",
      label.c_str(),
      static_cast<double>(counter.mean()),
      static_cast<double>(counter.std()),
      static_cast<double>(counter.min()),
      static_cast<double>(counter.max()));
  }
  printf("%s: Done\n", m_name.c_str());
};