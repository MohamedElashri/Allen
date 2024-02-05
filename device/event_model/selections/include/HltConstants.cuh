/*****************************************************************************\
* (c) Copyright 2020 CERN for the benefit of the LHCb Collaboration           *
*                                                                             *
* This software is distributed under the terms of the Apache License          *
* version 2 (Apache-2.0), copied verbatim in the file "LICENSE".              *
*                                                                             *
* In applying this licence, CERN does not waive the privileges and immunities *
* granted to it by virtue of its status as an Intergovernmental Organization  *
* or submit itself to any jurisdiction.                                       *
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
