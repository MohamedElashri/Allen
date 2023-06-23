/*****************************************************************************\
* (c) Copyright 2023 CERN for the benefit of the LHCb Collaboration           *
\*****************************************************************************/
#include "PlumeActivityLine.cuh"

// Explicit instantiation
INSTANTIATE_LINE(plume_activity_line::plume_activity_line_t, plume_activity_line::Parameters)

__device__ std::tuple<const uint64_t> plume_activity_line::plume_activity_line_t::get_input(
  const Parameters& parameters,
  const unsigned event_number,
  const unsigned)
{
  constexpr auto n_channel = sizeof(Plume_::ADC_counts) / sizeof(Plume_::bit_field);
  const Plume_* pl = parameters.dev_plume + event_number;

  uint64_t channels_over_thresh = 0ull;
  for (unsigned i = 0; i < n_channel; i++) {
    auto adc = static_cast<unsigned>(pl->ADC_counts[i].x & 0xffffffff);
    channels_over_thresh |= static_cast<uint64_t>(adc >= parameters.min_plume_adc) << i;
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
