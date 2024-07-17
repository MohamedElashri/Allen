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
#pragma once

#include <Common.h>
#include <CheckerTypes.h>
#include <CheckerInvoker.h>
#include "BackendCommon.h"
#include <mutex>

void checkHlt1Rate(
  const bool* decisions,
  const unsigned* decisions_atomics,
  const unsigned* track_offsets,
  const unsigned* sv_offsets,
  const unsigned selected_events,
  const unsigned requested_events);

double binomial_error(int n, int k);

class RateChecker : public Checker::BaseChecker {

private:
  // Event counters.
  std::vector<unsigned> m_counters;
  std::vector<std::string> m_line_names;
  unsigned m_tot;
  std::mutex m_mutex;

public:
  RateChecker(CheckerInvoker const*, std::string const&, std::string const&) { m_tot = 0; }

  void accumulate(const char* names_of_lines, gsl::span<const unsigned> dec_reports, const unsigned number_of_events);

  void report(const size_t requested_events) const override;
};
