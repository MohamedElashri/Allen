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
#include "LumiCommon.cuh"

INSTANTIATE_ALGORITHM(plume_lumi_counters::plume_lumi_counters_t)

void plume_lumi_counters::plume_lumi_counters_t::set_arguments_size(
  ArgumentReferences<Parameters> arguments,
  const RuntimeOptions&,
  const Constants&) const
{
  // the total size of output info is proportional to the lumi summaries
  set_size<dev_lumi_infos_t>(
    arguments, Lumi::Constants::n_plume_counters * first<host_lumi_summaries_count_t>(arguments));
}

void plume_lumi_counters::plume_lumi_counters_t::init()
{
  std::map<std::string, std::pair<unsigned, unsigned>> schema = property<lumi_counter_schema_t>();
  std::map<std::string, std::pair<float, float>> shifts_and_scales = property<lumi_counter_shifts_and_scales_t>();
  std::array<unsigned, 2 * Lumi::Constants::n_plume_counters> plume_offsets_and_sizes =
    property<plume_offsets_and_sizes_t>();
  std::array<float, 2 * Lumi::Constants::n_plume_counters> plume_shifts_and_scales =
    property<plume_shifts_and_scales_t>();

  unsigned c_idx(0u);
  for (auto counter_name : Lumi::Constants::plume_counter_names) {
    if (schema.find(counter_name) == schema.end()) {
      std::cout << "LumiSummary schema does not use " << counter_name << std::endl;
    }
    else {
      plume_offsets_and_sizes[2 * c_idx] = schema[counter_name].first;
      plume_offsets_and_sizes[2 * c_idx + 1] = schema[counter_name].second;
    }
    if (shifts_and_scales.find(counter_name) == shifts_and_scales.end()) {
      plume_shifts_and_scales[2 * c_idx] = 0.f;
      plume_shifts_and_scales[2 * c_idx + 1] = 1.f;
    }
    else {
      plume_shifts_and_scales[2 * c_idx] = shifts_and_scales[counter_name].first;
      plume_shifts_and_scales[2 * c_idx + 1] = shifts_and_scales[counter_name].second;
    }
    ++c_idx;
  }
  set_property_value<plume_offsets_and_sizes_t>(plume_offsets_and_sizes);
  set_property_value<plume_shifts_and_scales_t>(plume_shifts_and_scales);
}

void plume_lumi_counters::plume_lumi_counters_t::operator()(
  const ArgumentReferences<Parameters>& arguments,
  const RuntimeOptions&,
  const Constants&,
  const Allen::Context& context) const
{
  // do nothing if no lumi event
  if (first<host_lumi_summaries_count_t>(arguments) == 0) return;

  global_function(plume_lumi_counters)(dim3(4u), property<block_dim_t>(), context)(
    arguments, first<host_number_of_events_t>(arguments));
}

__global__ void plume_lumi_counters::plume_lumi_counters(
  plume_lumi_counters::Parameters parameters,
  const unsigned number_of_events)
{
  for (unsigned event_number = blockIdx.x * blockDim.x + threadIdx.x; event_number < number_of_events;
       event_number += blockDim.x * gridDim.x) {
    unsigned lumi_evt_index = parameters.dev_lumi_event_indices[event_number];

    // skip non-lumi event
    if (lumi_evt_index == parameters.dev_lumi_event_indices[event_number + 1]) continue;

    // loop over lumi channels
    const Plume_* pl = parameters.dev_plume + event_number;
    std::array<unsigned, 47> plume_counters = {0u, 0u, 0u, 0u, 0u, 0u, 0u, 0u, 0u, 0u, 0u, 0u, 0u, 0u, 0u, 0u,
                                               0u, 0u, 0u, 0u, 0u, 0u, 0u, 0u, 0u, 0u, 0u, 0u, 0u, 0u, 0u, 0u,
                                               0u, 0u, 0u, 0u, 0u, 0u, 0u, 0u, 0u, 0u, 0u, 0u, 0u, 0u, 0u};
    for (unsigned feb = 0; feb < 2; feb++) {
      unsigned channel_offset = feb * Lumi::Constants::n_plume_channels;
      for (unsigned channel = 0; channel < Lumi::Constants::n_plume_lumi_channels; ++channel) {
        plume_counters[0] += static_cast<unsigned>(pl->ADC_counts[channel_offset + channel].x & 0xffffffff);
        plume_counters[3 + feb * Lumi::Constants::n_plume_lumi_channels + channel] +=
          static_cast<unsigned>(pl->ADC_counts[channel_offset + channel].x & 0xffffffff);
        // get the corresponding overthreshold bit
        plume_counters[1 + feb] |= ((pl->ovr_th[feb]) & (1u << (21 - channel)));
      }
    }
    // get average
    plume_counters[0] = plume_counters[0] / 2u / Lumi::Constants::n_plume_lumi_channels;

    unsigned info_offset = Lumi::Constants::n_plume_counters * lumi_evt_index;
    for (unsigned i = 0u; i < Lumi::Constants::n_plume_counters; ++i) {
      fillLumiInfo(
        parameters.dev_lumi_infos[info_offset + i],
        parameters.plume_offsets_and_sizes.get()[2 * i],
        parameters.plume_offsets_and_sizes.get()[2 * i + 1],
        plume_counters[i],
        parameters.plume_shifts_and_scales.get()[2 * i],
        parameters.plume_shifts_and_scales.get()[2 * i + 1]);
    }
  }
}
