/*****************************************************************************\
* (c) Copyright 2020 CERN for the benefit of the LHCb Collaboration           *
\*****************************************************************************/
#pragma once

#include <cstdint>
#include "BackendCommon.h"

namespace Hlt1::Constants {
  constexpr short sourceID = 1 << 8; // canonical run3 source ID
  // old run2 source ID -- still used for SelReports as version not (yet) increased
  constexpr short sourceID_sel_reports = 1 << 13;
  // TODO: change to 12u, update to run3 source ID...
  constexpr short version_sel_reports = 11;
} // namespace Hlt1::Constants
