/*****************************************************************************\
* (c) Copyright 2020 CERN for the benefit of the LHCb Collaboration           *
\*****************************************************************************/
#include "PassthroughLine.cuh"

// Explicit instantiation
INSTANTIATE_LINE(passthrough_line::passthrough_line_t, passthrough_line::Parameters)

__device__ std::tuple<const bool>
passthrough_line::passthrough_line_t::get_input(const Parameters&, const unsigned) const
{
  return std::forward_as_tuple(true);
}

__device__ bool passthrough_line::passthrough_line_t::select(
  const Parameters&,
  std::tuple<const bool> input) const
{
  return std::get<0>(input);
}
