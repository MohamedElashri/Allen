/*****************************************************************************\
* (c) Copyright 2020 CERN for the benefit of the LHCb Collaboration           *
\*****************************************************************************/
#pragma once

#include <cstdint>
#include "BackendCommon.h"

namespace Hlt1::Constants {
  const short sourceID = 1 << 8; // canonical run3 source ID
  const short sourceID_sel_reports =
    1 << 13; // old run2 source ID -- still used for SelReports as version not (yet) increased
} // namespace Hlt1::Constants
