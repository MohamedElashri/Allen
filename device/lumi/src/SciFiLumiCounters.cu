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
#include "SciFiLumiCounters.cuh"
#include "LumiCommon.cuh"

#include "SciFiDefinitions.cuh"
#include "SciFiEventModel.cuh"

INSTANTIATE_ALGORITHM(scifi_lumi_counters::scifi_lumi_counters_t)

void scifi_lumi_counters::scifi_lumi_counters_t::set_arguments_size(
  ArgumentReferences<Parameters> arguments,
  const RuntimeOptions&,
  const Constants&) const
{
  // the total size of output info is proportional to the lumi summaries
  set_size<dev_lumi_infos_t>(
    arguments, Lumi::Constants::n_scifi_counters * first<host_lumi_summaries_count_t>(arguments));
}

void scifi_lumi_counters::scifi_lumi_counters_t::init()
{
  std::map<std::string, std::pair<unsigned, unsigned>> schema = property<lumi_counter_schema_t>();
  std::map<std::string, std::pair<float, float>> shifts_and_scales = property<lumi_counter_shifts_and_scales_t>();

  unsigned c_idx(0u);
  for (auto counter_name : Lumi::Constants::scifi_counter_names) {
    if (schema.find(counter_name) == schema.end()) {
      std::cout << "LumiSummary schema does not use " << counter_name << std::endl;
    }
    else {
      m_offsets_and_sizes[2 * c_idx] = schema[counter_name].first;
      m_offsets_and_sizes[2 * c_idx + 1] = schema[counter_name].second;
    }
    if (shifts_and_scales.find(counter_name) == shifts_and_scales.end()) {
      m_shifts_and_scales[2 * c_idx] = 0.f;
      m_shifts_and_scales[2 * c_idx + 1] = 1.f;
    }
    else {
      m_shifts_and_scales[2 * c_idx] = shifts_and_scales[counter_name].first;
      m_shifts_and_scales[2 * c_idx + 1] = shifts_and_scales[counter_name].second;
    }
    ++c_idx;
  }
}

void scifi_lumi_counters::scifi_lumi_counters_t::operator()(
  const ArgumentReferences<Parameters>& arguments,
  const RuntimeOptions&,
  const Constants& constants,
  const Allen::Context& context) const
{
  // do nothing if no lumi event
  if (first<host_lumi_summaries_count_t>(arguments) == 0) return;

  global_function(scifi_lumi_counters)(dim3(4u), property<block_dim_t>(), context)(
    arguments,
    first<host_number_of_events_t>(arguments),
    m_offsets_and_sizes,
    m_shifts_and_scales,
    constants.dev_scifi_geometry);
}

__global__ void scifi_lumi_counters::scifi_lumi_counters(
  scifi_lumi_counters::Parameters parameters,
  const unsigned number_of_events,
  const offsets_and_sizes_t offsets_and_sizes,
  const shifts_and_scales_t shifts_and_scales,
  const char* scifi_geometry)
{
  for (unsigned event_number = blockIdx.x * blockDim.x + threadIdx.x; event_number < number_of_events;
       event_number += blockDim.x * gridDim.x) {
    unsigned lumi_evt_index = parameters.dev_lumi_event_indices[event_number];

    // skip non-lumi event
    if (lumi_evt_index == parameters.dev_lumi_event_indices[event_number + 1]) continue;

    const SciFi::SciFiGeometry geom {scifi_geometry};

    SciFi::ConstHits hits {
      parameters.dev_scifi_hits,
      parameters.dev_scifi_hit_offsets[number_of_events * SciFi::Constants::n_mat_groups_and_mats]};
    SciFi::ConstHitCount hit_count {parameters.dev_scifi_hit_offsets, event_number};

    std::array<unsigned, 38> SciFiCounters = {0u, 0u, 0u, 0u, 0u, 0u, 0u, 0u, 0u, 0u, 0u, 0u, 0u,
                                              0u, 0u, 0u, 0u, 0u, 0u, 0u, 0u, 0u, 0u, 0u, 0u, 0u,
                                              0u, 0u, 0u, 0u, 0u, 0u, 0u, 0u, 0u, 0u, 0u, 0u};

    for (unsigned hit_index = 0u; hit_index < hit_count.event_number_of_hits(); ++hit_index) {
      const SciFi::SciFiChannelID id {hits.channel(hit_count.event_offset() + hit_index)};
      unsigned counter_id = 6 + 10 * (id.station() - 1) + 2 * id.module() + (id.quarter() % 2);
      ++SciFiCounters[counter_id];
      if (id.module() == 0u) continue;
      // SciFi::SciFiChannelID::station() starts from 1
      if (id.module() < 4)
        ++SciFiCounters[id.station() - 1];
      else
        ++SciFiCounters[id.station() + 2];
    }

    unsigned info_offset = Lumi::Constants::n_scifi_counters * lumi_evt_index;

    for (unsigned i = 0; i < Lumi::Constants::n_scifi_counters; ++i) {
      fillLumiInfo(
        parameters.dev_lumi_infos[info_offset + i],
        offsets_and_sizes[2 * i],
        offsets_and_sizes[2 * i + 1],
        SciFiCounters[i],
        shifts_and_scales[2 * i],
        shifts_and_scales[2 * i + 1]);
    }
  }
}
