/*****************************************************************************\
* (c) Copyright 2023 CERN for the benefit of the LHCb Collaboration           *
*                                                                             *
* This software is distributed under the terms of the Apache License          *
* version 2 (Apache-2.0), copied verbatim in the file "LICENSE".              *
*                                                                             *
* In applying this licence, CERN does not waive the privileges and immunities *
* granted to it by virtue of its status as an Intergovernmental Organization  *
* or submit itself to any jurisdiction.                                       *
\*****************************************************************************/
#include "PlumeActivityLine.cuh"

// Explicit instantiation
INSTANTIATE_LINE(plume_activity_line::plume_activity_line_t, plume_activity_line::Parameters)

__device__ std::tuple<const uint64_t> plume_activity_line::plume_activity_line_t::get_input(
  const Parameters& parameters,
  const unsigned event_number,
  const unsigned)
{
  const Plume_* pl = parameters.dev_plume + event_number;

  uint64_t channels_over_thresh = 0ull;
  for (unsigned i = 0; i < pl->ADC_counts.size(); i++) {
    channels_over_thresh |= static_cast<uint64_t>(pl->ADC_counts.at(i) >= parameters.min_plume_adc) << i;
  }

  return std::forward_as_tuple(channels_over_thresh);
}

__device__ bool plume_activity_line::plume_activity_line_t::select(
  const Parameters& parameters,
  std::tuple<const uint64_t> input)
{
  auto masked_cot = std::get<0>(input) & parameters.plume_channel_mask;
  unsigned number_of_adcs_over_thresh = 0;
  while (masked_cot) {
    number_of_adcs_over_thresh += masked_cot & 1ull;
    masked_cot >>= 1;
  }
  return number_of_adcs_over_thresh >= parameters.min_number_plume_adcs_over_min;
}
