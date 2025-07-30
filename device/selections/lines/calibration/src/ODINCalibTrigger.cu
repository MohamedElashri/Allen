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
#include "ODINCalibTrigger.cuh"
#include "Event/ODIN.h"

// Explicit instantiation
INSTANTIATE_LINE(odin_calib_line::odin_calib_line_t, odin_calib_line::Parameters)

__device__ bool odin_calib_line::odin_calib_line_t::select(const Parameters&, std::tuple<const ODINData&> input)
{
  LHCb::ODIN odin {std::get<0>(input)};
  return odin.triggerType() == to_integral(LHCb::ODIN::TriggerTypes::CalibrationTrigger);
}
