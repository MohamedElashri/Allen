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
#include "PVLumiCounters.cuh"
#include "LumiCommon.cuh"

INSTANTIATE_ALGORITHM(pv_lumi_counters::pv_lumi_counters_t)

void pv_lumi_counters::pv_lumi_counters_t::set_arguments_size(
  ArgumentReferences<Parameters> arguments,
  const RuntimeOptions&,
  const Constants&) const
{
  // the total size of output info is proportional to the lumi summaries
  set_size<dev_lumi_infos_t>(arguments, Lumi::Constants::n_pv_counters * first<host_lumi_summaries_count_t>(arguments));
}

void pv_lumi_counters::pv_lumi_counters_t::init()
{
  std::map<std::string, std::pair<unsigned, unsigned>> schema = property<lumi_counter_schema_t>();
  std::map<std::string, std::pair<float, float>> shifts_and_scales = property<lumi_counter_shifts_and_scales_t>();
  std::array<unsigned, 2 * Lumi::Constants::n_pv_counters> pv_offsets_and_sizes = property<pv_offsets_and_sizes_t>();
  std::array<float, 2 * Lumi::Constants::n_pv_counters> pv_shifts_and_scales = property<pv_shifts_and_scales_t>();

  unsigned c_idx(0u);
  for (auto counter_name : Lumi::Constants::pv_counter_names) {
    if (schema.find(counter_name) == schema.end()) {
      std::cout << "LumiSummary schema does not use " << counter_name << std::endl;
    }
    else {
      pv_offsets_and_sizes[2 * c_idx] = schema[counter_name].first;
      pv_offsets_and_sizes[2 * c_idx + 1] = schema[counter_name].second;
    }
    if (shifts_and_scales.find(counter_name) == shifts_and_scales.end()) {
      pv_shifts_and_scales[2 * c_idx] = 0.f;
      pv_shifts_and_scales[2 * c_idx + 1] = 1.f;
    }
    else {
      pv_shifts_and_scales[2 * c_idx] = shifts_and_scales[counter_name].first;
      pv_shifts_and_scales[2 * c_idx + 1] = shifts_and_scales[counter_name].second;
    }
    ++c_idx;
  }
  set_property_value<pv_offsets_and_sizes_t>(pv_offsets_and_sizes);
  set_property_value<pv_shifts_and_scales_t>(pv_shifts_and_scales);
}

void pv_lumi_counters::pv_lumi_counters_t::operator()(
  const ArgumentReferences<Parameters>& arguments,
  const RuntimeOptions&,
  const Constants&,
  const Allen::Context& context) const
{
  // do nothing if no lumi event
  if (first<host_lumi_summaries_count_t>(arguments) == 0) return;

  global_function(pv_lumi_counters)(dim3(4u), property<block_dim_t>(), context)(
    arguments, first<host_number_of_events_t>(arguments));
}

__global__ void pv_lumi_counters::pv_lumi_counters(
  pv_lumi_counters::Parameters parameters,
  const unsigned number_of_events)
{
  for (unsigned event_number = blockIdx.x * blockDim.x + threadIdx.x; event_number < number_of_events;
       event_number += blockDim.x * gridDim.x) {
    unsigned lumi_evt_index = parameters.dev_lumi_event_indices[event_number];

    // skip non-lumi event
    if (lumi_evt_index == parameters.dev_lumi_event_indices[event_number + 1]) continue;

    // number of PVs
    std::array<float, Lumi::Constants::n_pv_counters> pv_counters = {0u, 0u, 0u, 0u, 0u};
    pv_counters[0] = parameters.dev_number_of_pvs[event_number];

    if (parameters.dev_number_of_pvs[event_number] > 0) {
      // select quasi-random PV
      unsigned index_pv = event_number % parameters.dev_number_of_pvs[event_number];
      const PV::Vertex* vertices = parameters.dev_multi_final_vertices + event_number * PV::max_number_vertices;
      auto pv_pos = vertices[index_pv].position;
      pv_counters[2] = pv_pos.x;
      pv_counters[3] = pv_pos.y;
      pv_counters[4] = pv_pos.z;

      // count vertices in fiducial volume
      for (unsigned pv_index = 0u; pv_index < pv_counters[0]; ++pv_index) {
        auto x = vertices[pv_index].position.x;
        auto y = vertices[pv_index].position.y;
        auto absz = fabsf(vertices[pv_index].position.z);
        if (absz < 300 && sqrtf(x * x + y * y) < 3) ++pv_counters[1];
      }
    }

    unsigned info_offset = Lumi::Constants::n_pv_counters * lumi_evt_index;
    for (unsigned i = 0; i < Lumi::Constants::n_pv_counters; ++i) {
      fillLumiInfo(
        parameters.dev_lumi_infos[info_offset + i],
        parameters.pv_offsets_and_sizes.get()[2 * i],
        parameters.pv_offsets_and_sizes.get()[2 * i + 1],
        pv_counters[i],
        parameters.pv_shifts_and_scales.get()[2 * i],
        parameters.pv_shifts_and_scales.get()[2 * i + 1]);
    }
  }
}
