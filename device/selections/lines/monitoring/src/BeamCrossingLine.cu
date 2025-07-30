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
#include "BeamCrossingLine.cuh"
#include "Event/ODIN.h"

// Explicit instantiation
INSTANTIATE_LINE(beam_crossing_line::beam_crossing_line_t, beam_crossing_line::Parameters)

__device__ bool beam_crossing_line::beam_crossing_line_t::select(
  const Parameters&,
  const DeviceProperties& properties,
  std::tuple<const ODINData&> input)
{
  const unsigned bxt = to_integral(LHCb::ODIN {std::get<0>(input)}.bunchCrossingType());
  if (bxt == properties.beam_crossing_type) return true;

  return false;
}
