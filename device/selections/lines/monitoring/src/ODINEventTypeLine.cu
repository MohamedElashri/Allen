/*****************************************************************************\
* (c) Copyright 2020 CERN for the benefit of the LHCb Collaboration           *
\*****************************************************************************/
#include "ODINEventTypeLine.cuh"
#include "ODINBank.cuh"
#include "Event/ODIN.h"

// Explicit instantiation
INSTANTIATE_LINE(odin_event_type_line::odin_event_type_line_t, odin_event_type_line::Parameters)

__device__ bool odin_event_type_line::odin_event_type_line_t::select(
  const Parameters& parameters,
  std::tuple<const ODINData&> input)
{
  const auto event_type = LHCb::ODIN{std::get<0>(input)}.eventType();
  return event_type & parameters.odin_event_type;
}
