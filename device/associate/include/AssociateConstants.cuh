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

/**
   Contains constants needed for associations
   - cut values

 */
#include "SystemOfUnits.h"
#include <cassert>

namespace Associate {
  namespace VeloPVIP {
    constexpr float baseline = 50.f * Allen::Units::um;
  }
  namespace KalmanPVIP {
    constexpr float baseline = 100.f;
  }
} // namespace Associate
