/*****************************************************************************\
* (c) Copyright 2023 CERN for the benefit of the LHCb Collaboration           *
\*****************************************************************************/
#include "PlumeActivityLine.cuh"

// Explicit instantiation
INSTANTIATE_LINE(plume_activity_line::plume_activity_line_t, plume_activity_line::Parameters)

__device__ std::tuple<const unsigned> plume_activity_line::plume_activity_line_t::get_input(
  const Parameters& parameters,
  const unsigned event_number,
  const unsigned)
{
  unsigned n_adcs_over = 0u;
  const Plume_* pl = parameters.dev_plume + event_number;

  for (auto channel : pl->ADC_counts) {
    auto adc = static_cast<unsigned>(channel.x & 0xffffffff);
    if (adc > parameters.min_plume_adc) n_adcs_over++;
  }

  return std::forward_as_tuple(n_adcs_over);
}

__device__ bool plume_activity_line::plume_activity_line_t::select(
  const Parameters& parameters,
  std::tuple<const unsigned> input)
{
  const auto number_of_adcs_over_thresh = std::get<0>(input);
  return number_of_adcs_over_thresh >= parameters.min_number_plume_adcs_over_min;
}
