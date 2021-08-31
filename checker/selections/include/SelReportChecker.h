/*****************************************************************************\
* (c) Copyright 2021 CERN for the benefit of the LHCb Collaboration           *
*                                                                             *
* This software is distributed under the terms of the Apache License          *
* version 2 (Apache-2.0), copied verbatim in the file "COPYING".              *
*                                                                             *
* In applying this licence, CERN does not waive the privileges and immunities *
* granted to it by virtue of its status as an Intergovernmental Organization  *
* or submit itself to any jurisdiction.                                       *
\*****************************************************************************/
#pragma once

#include <Common.h>
#include <CheckerTypes.h>
#include <CheckerInvoker.h>
#include <fstream>
#include "BackendCommon.h"
#include "SelReportCheckerTypes.h"
#include <mutex>

class SelReportChecker : public Checker::BaseChecker {

private:
  std::vector<std::vector<unsigned>> m_selreports;
  std::vector<std::string> m_line_names;
  std::vector<unsigned> m_event_counters;
  std::vector<unsigned> m_candidates_counters;
  unsigned m_stdinfo_counter;
  unsigned m_hits_counter;
  unsigned m_dec_counter;
  unsigned m_track_counter;
  unsigned m_sv_counter;
  std::mutex m_mutex;

public:
  struct SelRepTag {
    static std::string const name;
  };

  using subdetector_t = SelRepTag;

  SelReportChecker(CheckerInvoker const*, std::string const&, std::string const&) {};

  virtual ~SelReportChecker() = default;

  void accumulate(
    const std::vector<std::string>& name_of_lines,
    const unsigned* sel_reps,
    const unsigned* sel_rep_offsets,
    const unsigned number_of_events);

  void report(size_t) const override;
};
