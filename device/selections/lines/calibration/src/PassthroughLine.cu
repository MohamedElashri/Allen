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
#include "PassthroughLine.cuh"

// Explicit instantiation
INSTANTIATE_LINE(passthrough_line::passthrough_line_t, passthrough_line::Parameters)

__device__ std::tuple<const bool>
passthrough_line::passthrough_line_t::get_input(const Parameters&, const unsigned, const unsigned)
{
  return std::forward_as_tuple(true);
}

__device__ bool passthrough_line::passthrough_line_t::select(const Parameters&, std::tuple<const bool> input)
{
  return std::get<0>(input);
}
