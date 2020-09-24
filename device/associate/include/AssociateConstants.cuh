/*****************************************************************************\
* (c) Copyright 2018-2020 CERN for the benefit of the LHCb Collaboration      *
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
    constexpr float baseline = 50.f * Gaudi::Units::um;
  }
  namespace KalmanPVIPChi2 {
    constexpr float baseline = 100.f;
  }
} // namespace Associate
