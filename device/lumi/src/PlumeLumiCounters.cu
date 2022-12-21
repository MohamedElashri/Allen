/*****************************************************************************\
* (c) Copyright 2022 CERN for the benefit of the LHCb Collaboration           *
*                                                                             *
* This software is distributed under the terms of the Apache License          *
* version 2 (Apache-2.0), copied verbatim in the file "COPYING".              *
*                                                                             *
* In applying this licence, CERN does not waive the privileges and immunities *
* granted to it by virtue of its status as an Intergovernmental Organization  *
* or submit itself to any jurisdiction.                                       *
\*****************************************************************************/
#include "PlumeLumiCounters.cuh"

INSTANTIATE_ALGORITHM(plume_lumi_counters::plume_lumi_counters_t)

void plume_lumi_counters::plume_lumi_counters_t::set_arguments_size(
  ArgumentReferences<Parameters> arguments,
  const RuntimeOptions&,
  const Constants&) const
{
  // the total size of output info is proportional to the lumi summaries
  set_size<dev_lumi_infos_t>(
    arguments,
    Lumi::Constants::n_plume_counters * first<host_lumi_summaries_size_t>(arguments) / Lumi::Constants::lumi_length);
}

void plume_lumi_counters::plume_lumi_counters_t::operator()(
  const ArgumentReferences<Parameters>& arguments,
  const RuntimeOptions&,
  const Constants&,
  const Allen::Context& context) const
{
  // do nothing if no lumi event
  if (first<host_lumi_summaries_size_t>(arguments) == 0) return;

  global_function(plume_lumi_counters)(dim3(4u), property<block_dim_t>(), context)(
    arguments, first<host_number_of_events_t>(arguments));
}

__global__ void plume_lumi_counters::plume_lumi_counters(
  plume_lumi_counters::Parameters parameters,
  const unsigned number_of_events)
{
  for (unsigned event_number = blockIdx.x * blockDim.x + threadIdx.x; event_number < number_of_events;
       event_number += blockDim.x * gridDim.x) {
    unsigned lumi_sum_offset = parameters.dev_lumi_summary_offsets[event_number];

    // skip non-lumi event
    if (lumi_sum_offset == parameters.dev_lumi_summary_offsets[event_number + 1]) continue;

    // loop over lumi channels
    const Plume_* pl = parameters.dev_plume + event_number;
    std::array<unsigned, 3> plume_counters = {0u, 0u, 0u};
    for (unsigned feb = 0; feb < 2; feb++) {
      unsigned channel_offset = feb * Lumi::Constants::n_plume_channels;
      for (unsigned channel = 0; channel < Lumi::Constants::n_plume_lumi_channels; ++channel) {
        plume_counters[0] += static_cast<unsigned>(pl->ADC_counts[channel_offset + channel].x & 0xffffffff);
        // get the corresonding overthreshold bit
        plume_counters[1 + feb] |= ((pl->ovr_th[feb]) & (1u << (31 - channel)));
      }
    }
    // get average
    plume_counters[0] = plume_counters[0] / 2u / Lumi::Constants::n_plume_lumi_channels;

    std::array<LHCb::LumiSummaryOffsets::V2::counterOffsets, Lumi::Constants::n_plume_counters> counter_offsets = {
      LHCb::LumiSummaryOffsets::V2::PlumeAvgLumiADCOffset,
      LHCb::LumiSummaryOffsets::V2::PlumeLumiOverthrLowOffset,
      LHCb::LumiSummaryOffsets::V2::PlumeLumiOverthrHighOffset};
    std::array<LHCb::LumiSummaryOffsets::V2::counterOffsets, Lumi::Constants::n_plume_counters> counter_sizes = {
      LHCb::LumiSummaryOffsets::V2::PlumeAvgLumiADCSize,
      LHCb::LumiSummaryOffsets::V2::PlumeLumiOverthrLowSize,
      LHCb::LumiSummaryOffsets::V2::PlumeLumiOverthrHighSize};
    auto* lumi_info =
      parameters.dev_lumi_infos + Lumi::Constants::n_plume_counters * lumi_sum_offset / Lumi::Constants::lumi_length;
    for (unsigned info_index = 0u; info_index < Lumi::Constants::n_plume_counters; ++info_index) {
      lumi_info[info_index].offset = counter_offsets[info_index];
      lumi_info[info_index].size = counter_sizes[info_index];
      lumi_info[info_index].value = plume_counters[info_index];
    }
  }
}
