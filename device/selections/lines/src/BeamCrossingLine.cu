#include "BeamCrossingLine.cuh"
#include "Event/ODIN.h"

// Explicit instantiation
INSTANTIATE_LINE(beam_crossing_line::beam_crossing_line_t, beam_crossing_line::Parameters)

__device__ bool beam_crossing_line::beam_crossing_line_t::select(
  const Parameters& parameters,
  std::tuple<const char*> input) const
{
  const auto& odin = std::get<0>(input);

  const unsigned hdr_size = 8;
  const uint32_t* odinData = reinterpret_cast<const uint32_t*>(
    odin + hdr_size);
  const uint32_t word8 = odinData[LHCb::ODIN::Data::Word8];
  const unsigned bxt = (word8 & LHCb::ODIN::BXTypeMask) >> LHCb::ODIN::BXTypeBits;
  if (bxt == parameters.beam_crossing_type) return true;

  return false;
}
