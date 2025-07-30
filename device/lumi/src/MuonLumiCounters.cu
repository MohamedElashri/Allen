/***************************************************************************** \
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
  std::map<std::string, std::pair<unsigned, unsigned>> schema = m_lumi_counter_schema;
  std::map<std::string, std::pair<float, float>> shifts_and_scales = m_lumi_counter_shifts_and_scales;

  unsigned c_idx(0u);
  for (auto counter_name : Lumi::Constants::muon_counter_names) {
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

void muon_lumi_counters::muon_lumi_counters_t::operator()(
  const ArgumentReferences<Parameters>& arguments,
  const RuntimeOptions&,
  const Constants&,
  const Allen::Context& context) const
{
  // do nothing if no lumi event
  if (first<host_lumi_summaries_count_t>(arguments) == 0) return;

  Allen::memset_async<dev_lumi_infos_t>(arguments, 0, context);

  global_function(muon_lumi_counters)(dim3(4u), m_block_dim, context)(
    arguments,
    first<host_number_of_events_t>(arguments),
    size<dev_event_list_t>(arguments),
    first<host_raw_bank_version_t>(arguments),
    m_offsets_and_sizes,
    m_shifts_and_scales);
}

__global__ void muon_lumi_counters::muon_lumi_counters(
  muon_lumi_counters::Parameters parameters,
  const unsigned number_of_events,
  const unsigned number_of_gec_events,
  const int decoding_version,
  const offsets_and_sizes_t offsets_and_sizes,
  const shifts_and_scales_t shifts_and_scales)
{
  // first fill 'decoding' counters, which are available even if the GEC does not pass
  for (unsigned event_number = blockIdx.x * blockDim.x + threadIdx.x; event_number < number_of_events;
       event_number += blockDim.x * gridDim.x) {
    unsigned lumi_evt_index = parameters.dev_lumi_event_indices[event_number];

    // skip non-lumi event
    if (lumi_evt_index == parameters.dev_lumi_event_indices[event_number + 1]) continue;

    const auto muon_hits_offsets =
      parameters.dev_storage_station_region_quarter_offsets + event_number * Lumi::Constants::MuonBankSize;
    const auto event_number_of_hits = muon_hits_offsets[Lumi::Constants::MuonBankSize] - muon_hits_offsets[0];

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
        offsets_and_sizes[2 * i],
        offsets_and_sizes[2 * i + 1],
        muon_hits_offsets[muon_offsets[i + 1]] - muon_hits_offsets[muon_offsets[i]],
        shifts_and_scales[2 * i],
        shifts_and_scales[2 * i + 1]);
    }

    const auto tell_number = parameters.dev_muon_tell_number + muon_hits_offsets[0];
    std::array<unsigned, Muon::Constants::maxTell40Number> hits_per_tell = {0u, 0u, 0u, 0u, 0u, 0u, 0u, 0u, 0u, 0u, 0u,
                                                                            0u, 0u, 0u, 0u, 0u, 0u, 0u, 0u, 0u, 0u, 0u};
    unsigned firstTell = 1u;
    // tell number starts from 0 for decoding version 2
    // and only 10 tell numbers defined
    if (decoding_version == 2) {
      firstTell = 0u;
      for (unsigned i = 10u; i < Muon::Constants::maxTell40Number; ++i)
        hits_per_tell[i] = 0xffffffff;
    }
    for (unsigned i = 0; i < event_number_of_hits; ++i) {
      assert(tell_number[i] <= Muon::Constants::maxTell40Number);
      ++hits_per_tell[tell_number[i] - firstTell];
    }
    for (unsigned i = Lumi::Constants::n_muon_station_regions + 1u; i < Lumi::Constants::n_muon_counters; ++i) {
      fillLumiInfo(
        parameters.dev_lumi_infos[info_offset + i],
        offsets_and_sizes[2 * i],
        offsets_and_sizes[2 * i + 1],
        hits_per_tell[i - Lumi::Constants::n_muon_station_regions - 1u],
        shifts_and_scales[2 * i],
        shifts_and_scales[2 * i + 1]);
    }
  }

  // now fill counters that are only available inside the GEC
  for (unsigned event_index = blockIdx.x * blockDim.x + threadIdx.x; event_index < number_of_gec_events;
       event_index += blockDim.x * gridDim.x) {
    auto event_number = parameters.dev_event_list[event_index];
    unsigned lumi_evt_index = parameters.dev_lumi_event_indices[event_number];

    // skip non-lumi event
    if (lumi_evt_index == parameters.dev_lumi_event_indices[event_number + 1]) continue;

    unsigned info_offset = Lumi::Constants::n_muon_counters * lumi_evt_index;

    fillLumiInfo(
      parameters.dev_lumi_infos[info_offset + Lumi::Constants::n_muon_station_regions],
      offsets_and_sizes[2 * Lumi::Constants::n_muon_station_regions],
      offsets_and_sizes[2 * Lumi::Constants::n_muon_station_regions + 1],
      parameters.dev_muon_tracks_offsets[event_number + 1] - parameters.dev_muon_tracks_offsets[event_number],
      shifts_and_scales[2 * Lumi::Constants::n_muon_station_regions],
      shifts_and_scales[2 * Lumi::Constants::n_muon_station_regions + 1]);
  }
}
