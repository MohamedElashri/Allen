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
#include "VeloLumiCounters.cuh"
#include "LumiCommon.cuh"

INSTANTIATE_ALGORITHM(velo_lumi_counters::velo_lumi_counters_t)

void velo_lumi_counters::velo_lumi_counters_t::set_arguments_size(
  ArgumentReferences<Parameters> arguments,
  const RuntimeOptions&,
  const Constants&) const
{
  // convert the size of lumi summaries to the size of velo counter infos
  set_size<dev_lumi_infos_t>(
    arguments,
    Lumi::Constants::n_velo_counters * first<host_lumi_summaries_size_t>(arguments) / property<lumi_sum_length_t>());
}

void velo_lumi_counters::velo_lumi_counters_t::init()
{
  std::map<std::string, std::pair<unsigned, unsigned>> schema = property<lumi_counter_schema_t>();

  if (schema.find("VeloTracks") == schema.end()) {
    std::cout << "LumiSummary schema does not use VeloTracks" << std::endl;
  }
  else {
    set_property_value<velo_tracks_offset_and_size_t>(schema["VeloTracks"]);
  }
}

void velo_lumi_counters::velo_lumi_counters_t::operator()(
  const ArgumentReferences<Parameters>& arguments,
  const RuntimeOptions&,
  const Constants&,
  const Allen::Context& context) const
{
  // do nothing if no lumi event
  if (first<host_lumi_summaries_size_t>(arguments) == 0) return;

  global_function(velo_lumi_counters)(
    dim3(first<host_number_of_events_t>(arguments)), property<block_dim_t>(), context)(
    arguments, first<host_number_of_events_t>(arguments));
}

__global__ void velo_lumi_counters::velo_lumi_counters(
  velo_lumi_counters::Parameters parameters,
  const unsigned number_of_events)
{
  for (unsigned event_number = blockIdx.x * blockDim.x + threadIdx.x; event_number < number_of_events;
       event_number += blockDim.x * gridDim.x) {
    unsigned lumi_sum_offset = parameters.dev_lumi_summary_offsets[event_number];

    // skip non-lumi event
    if (lumi_sum_offset == parameters.dev_lumi_summary_offsets[event_number + 1]) continue;

    unsigned info_offset = lumi_sum_offset / parameters.lumi_sum_length;

    fillLumiInfo(parameters.dev_lumi_infos[info_offset],
                 parameters.velo_tracks_offset_and_size,
                 parameters.dev_offsets_all_velo_tracks[event_number + 1] - parameters.dev_offsets_all_velo_tracks[event_number]);
  }
}
