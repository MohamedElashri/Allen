#include "GECPassthroughLine.cuh"

// Explicit instantiation
INSTANTIATE_LINE(gec_passthrough_line::gec_passthrough_line_t, gec_passthrough_line::Parameters)

__device__ std::tuple<const bool>
gec_passthrough_line::gec_passthrough_line_t::get_input(const Parameters&, const unsigned) const
{
  return std::forward_as_tuple(true);
}

__device__ bool gec_passthrough_line::gec_passthrough_line_t::select(
  const Parameters&,
  std::tuple<const bool> input) const
{
  const auto gec_decision = std::get<0>(input);
  return gec_decision;
}
