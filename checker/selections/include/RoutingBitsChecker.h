/*****************************************************************************\
* (c) Copyright 2018-2020 CERN for the benefit of the LHCb Collaboration      *
\*****************************************************************************/
#pragma once

#include <Common.h>
#include <CheckerTypes.h>
#include <CheckerInvoker.h>
#include "BackendCommon.h"
#include <mutex>

class RoutingBitsChecker : public Checker::BaseChecker {

private:
  // Event counters.
  std::vector<unsigned> m_counters;
  std::vector<std::string> m_line_names;
  std::map<std::string, uint32_t> m_rb_map;
  unsigned m_tot;
  std::mutex m_mutex;

public:
  RoutingBitsChecker(CheckerInvoker const*, std::string const&, std::string const&) { m_tot = 0; }

  void accumulate(const uint32_t* routing_bits, const unsigned number_of_events);

  void report(size_t) const override;
};
