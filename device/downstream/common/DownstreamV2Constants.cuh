/*****************************************************************************\
* (c) Copyright 2024 CERN for the benefit of the LHCb Collaboration          *
*                                                                             *
* This software is distributed under the terms of the Apache License          *
* version 2 (Apache-2.0), copied verbatim in the file "LICENSE".              *
*                                                                             *
* In applying this licence, CERN does not waive the privileges and immunities *
* granted to it by virtue of its status as an Intergovernmental Organization  *
* or submit itself to any jurisdiction.                                       *
\*****************************************************************************/
#pragma once

#include "UTDefinitions.cuh"

namespace Downstream::Constants {
  constexpr unsigned MaxNumSectorGroupInLayer = 4;
  constexpr unsigned MaxNumSectorGroup = UT::Constants::n_layers * MaxNumSectorGroupInLayer;
  constexpr unsigned MaxNumSharedMemoryInCloneKilling = 2000;
} // namespace Downstream::Constants
