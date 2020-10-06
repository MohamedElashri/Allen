#include "ODINEventTypeLine.cuh"
#include "Event/ODIN.h"

// Explicit instantiation
INSTANTIATE_LINE(odin_event_type_line::odin_event_type_line_t, odin_event_type_line::Parameters)

__device__ bool odin_event_type_line::odin_event_type_line_t::select(
  const Parameters& parameters,
  std::tuple<const unsigned*> input) const
{
  const uint32_t word2 = std::get<0>(input)[LHCb::ODIN::Data::EventType];
  return word2 & parameters.odin_event_type;
}
