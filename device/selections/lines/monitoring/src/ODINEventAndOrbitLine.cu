/*****************************************************************************\
* (c) Copyright 2020 CERN for the benefit of the LHCb Collaboration           *
\*****************************************************************************/
#include "ODINEventAndOrbitLine.cuh"
#include "ODINBank.cuh"
#include "Event/ODIN.h"

// Explicit instantiation
INSTANTIATE_LINE(odin_event_and_orbit_line::odin_event_and_orbit_line_t, odin_event_and_orbit_line::Parameters)

__device__ bool odin_event_and_orbit_line::odin_event_and_orbit_line_t::select(
  const Parameters& parameters,
  std::tuple<const ODINData> input)
{
  const auto event_type = LHCb::ODIN {std::get<0>(input)}.eventType();
  const auto orbit_number = LHCb::ODIN {std::get<0>(input)}.orbitNumber();
  return (event_type & parameters.odin_event_type) &&
         (orbit_number % parameters.odin_orbit_modulo == parameters.odin_orbit_remainder);
}
