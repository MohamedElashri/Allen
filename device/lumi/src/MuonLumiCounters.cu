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
#include "MuonLumiCounters.cuh"
#include "LumiCommon.cuh"

INSTANTIATE_ALGORITHM(muon_lumi_counters::muon_lumi_counters_t)

void muon_lumi_counters::muon_lumi_counters_t::set_arguments_size(
  ArgumentReferences<Parameters> arguments,
  const RuntimeOptions&,
  const Constants&) const
{
  // the total size of output info is proportional to the lumi summaries
  set_size<dev_lumi_infos_t>(
    arguments, Lumi::Constants::n_muon_counters * first<host_lumi_summaries_count_t>(arguments));
}

void muon_lumi_counters::muon_lumi_counters_t::init()
{
  std::map<std::string, std::pair<unsigned, unsigned>> schema = property<lumi_counter_schema_t>();
  std::map<std::string, std::pair<float, float>> shifts_and_scales = property<lumi_counter_shifts_and_scales_t>();
  std::array<unsigned, 2 * Lumi::Constants::n_muon_counters> muon_offsets_and_sizes =
    property<muon_offsets_and_sizes_t>();
  std::array<float, 2 * Lumi::Constants::n_muon_counters> muon_shifts_and_scales = property<muon_shifts_and_scales_t>();

  unsigned c_idx(0u);
  for (auto counter_name : Lumi::Constants::muon_counter_names) {
    if (schema.find(counter_name) == schema.end()) {
      std::cout << "LumiSummary schema does not use " << counter_name << std::endl;
    }
    else {
      muon_offsets_and_sizes[2 * c_idx] = schema[counter_name].first;
      muon_offsets_and_sizes[2 * c_idx + 1] = schema[counter_name].second;
    }
    if (shifts_and_scales.find(counter_name) == shifts_and_scales.end()) {
      muon_shifts_and_scales[2 * c_idx] = 0.f;
      muon_shifts_and_scales[2 * c_idx + 1] = 1.f;
    }
    else {
      muon_shifts_and_scales[2 * c_idx] = shifts_and_scales[counter_name].first;
      muon_shifts_and_scales[2 * c_idx + 1] = shifts_and_scales[counter_name].second;
    }
    ++c_idx;
  }
  set_property_value<muon_offsets_and_sizes_t>(muon_offsets_and_sizes);
  set_property_value<muon_shifts_and_scales_t>(muon_shifts_and_scales);
}

void muon_lumi_counters::muon_lumi_counters_t::operator()(
  const ArgumentReferences<Parameters>& arguments,
  const RuntimeOptions&,
  const Constants&,
  const Allen::Context& context) const
{
  // do nothing if no lumi event
  if (first<host_lumi_summaries_count_t>(arguments) == 0) return;

  global_function(muon_lumi_counters)(dim3(4u), property<block_dim_t>(), context)(
    arguments, first<host_number_of_events_t>(arguments));
}

__global__ void muon_lumi_counters::muon_lumi_counters(
  muon_lumi_counters::Parameters parameters,
  const unsigned number_of_events)
{
  for (unsigned event_number = blockIdx.x * blockDim.x + threadIdx.x; event_number < number_of_events;
       event_number += blockDim.x * gridDim.x) {
    unsigned lumi_evt_index = parameters.dev_lumi_event_indices[event_number];

    // skip non-lumi event
    if (lumi_evt_index == parameters.dev_lumi_event_indices[event_number + 1]) continue;

    const auto muon_hits_offsets =
      parameters.dev_storage_station_region_quarter_offsets + event_number * Lumi::Constants::MuonBankSize;

    unsigned info_offset = Lumi::Constants::n_muon_counters * lumi_evt_index;

    std::array<unsigned, Lumi::Constants::n_muon_station_regions + 1> muon_offsets = {Lumi::Constants::M2R1,
                                                                                      Lumi::Constants::M2R2,
                                                                                      Lumi::Constants::M2R3,
                                                                                      Lumi::Constants::M2R4,
                                                                                      Lumi::Constants::M3R1,
                                                                                      Lumi::Constants::M3R2,
                                                                                      Lumi::Constants::M3R3,
                                                                                      Lumi::Constants::M3R4,
                                                                                      Lumi::Constants::M4R1,
                                                                                      Lumi::Constants::M4R2,
                                                                                      Lumi::Constants::M4R3,
                                                                                      Lumi::Constants::M4R4,
                                                                                      Lumi::Constants::M5R1};

    for (unsigned i = 0; i < Lumi::Constants::n_muon_station_regions; ++i) {
      fillLumiInfo(
        parameters.dev_lumi_infos[info_offset + i],
        parameters.muon_offsets_and_sizes.get()[2 * i],
        parameters.muon_offsets_and_sizes.get()[2 * i + 1],
        muon_hits_offsets[muon_offsets[i + 1]] - muon_hits_offsets[muon_offsets[i]],
        parameters.muon_shifts_and_scales.get()[2 * i],
        parameters.muon_shifts_and_scales.get()[2 * i + 1]);
    }

    fillLumiInfo(
      parameters.dev_lumi_infos[info_offset + Lumi::Constants::n_muon_station_regions],
      parameters.muon_offsets_and_sizes.get()[2 * Lumi::Constants::n_muon_station_regions],
      parameters.muon_offsets_and_sizes.get()[2 * Lumi::Constants::n_muon_station_regions + 1],
      parameters.dev_muon_number_of_tracks[event_number],
      parameters.muon_shifts_and_scales.get()[2 * Lumi::Constants::n_muon_station_regions],
      parameters.muon_shifts_and_scales.get()[2 * Lumi::Constants::n_muon_station_regions + 1]);
  }
}
