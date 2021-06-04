/*****************************************************************************\
* (c) Copyright 2020 CERN for the benefit of the LHCb Collaboration           *
\*****************************************************************************/
#include "BeamCrossingLine.cuh"
#include "Event/ODIN.h"

// Explicit instantiation
INSTANTIATE_LINE(beam_crossing_line::beam_crossing_line_t, beam_crossing_line::Parameters)

__device__ bool beam_crossing_line::beam_crossing_line_t::select(
  const Parameters& parameters,
  std::tuple<const unsigned*> input)
{
  const unsigned bxt = static_cast<unsigned int>(LHCb::ODIN({std::get<0>(input), 10}).bunchCrossingType());
  if (bxt == parameters.beam_crossing_type) return true;

  return false;
}
