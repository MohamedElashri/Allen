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
#include "LumiSummaryOffsets.h"

INSTANTIATE_ALGORITHM(muon_lumi_counters::muon_lumi_counters_t)

void muon_lumi_counters::muon_lumi_counters_t::set_arguments_size(
  ArgumentReferences<Parameters> arguments,
  const RuntimeOptions&,
  const Constants&) const
{
  // convert the size of lumi summaries to the size of muon counter infos
  set_size<dev_lumi_infos_t>(
    arguments,
    Lumi::Constants::n_muon_counters * first<host_lumi_summaries_size_t>(arguments) / Lumi::Constants::lumi_length);
}

void muon_lumi_counters::muon_lumi_counters_t::operator()(
  const ArgumentReferences<Parameters>& arguments,
  const RuntimeOptions&,
  const Constants&,
  const Allen::Context& context) const
{
  // do nothing if no lumi event
  if (first<host_lumi_summaries_size_t>(arguments) == 0) return;

  global_function(muon_lumi_counters)(
    dim3(first<host_number_of_events_t>(arguments)), property<block_dim_t>(), context)(
    arguments, first<host_number_of_events_t>(arguments));
}

__global__ void muon_lumi_counters::muon_lumi_counters(
  muon_lumi_counters::Parameters parameters,
  const unsigned number_of_events)
{
  for (unsigned event_number = blockIdx.x * blockDim.x + threadIdx.x; event_number < number_of_events;
       event_number += blockDim.x * gridDim.x) {
    unsigned lumi_sum_offset = parameters.dev_lumi_summary_offsets[event_number];

    // skip non-lumi event
    if (lumi_sum_offset == parameters.dev_lumi_summary_offsets[event_number + 1]) continue;

    const auto muon_hits_offsets =
      parameters.dev_storage_station_region_quarter_offsets + event_number * Lumi::Constants::MuonBankSize;

    unsigned muon_info_offset = 12u * lumi_sum_offset / Lumi::Constants::lumi_length;
    // M2R1
    parameters.dev_lumi_infos[muon_info_offset].size = LHCb::LumiSummaryOffsets::V2::MuonHitsM2R1Size;
    parameters.dev_lumi_infos[muon_info_offset].offset = LHCb::LumiSummaryOffsets::V2::MuonHitsM2R1Offset;
    parameters.dev_lumi_infos[muon_info_offset].value =
      muon_hits_offsets[Lumi::Constants::M2R2] - muon_hits_offsets[Lumi::Constants::M2R1];

    // M2R2
    ++muon_info_offset;
    parameters.dev_lumi_infos[muon_info_offset].size = LHCb::LumiSummaryOffsets::V2::MuonHitsM2R2Size;
    parameters.dev_lumi_infos[muon_info_offset].offset = LHCb::LumiSummaryOffsets::V2::MuonHitsM2R2Offset;
    parameters.dev_lumi_infos[muon_info_offset].value =
      muon_hits_offsets[Lumi::Constants::M2R3] - muon_hits_offsets[Lumi::Constants::M2R2];

    // M2R3
    ++muon_info_offset;
    parameters.dev_lumi_infos[muon_info_offset].size = LHCb::LumiSummaryOffsets::V2::MuonHitsM2R3Size;
    parameters.dev_lumi_infos[muon_info_offset].offset = LHCb::LumiSummaryOffsets::V2::MuonHitsM2R3Offset;
    parameters.dev_lumi_infos[muon_info_offset].value =
      muon_hits_offsets[Lumi::Constants::M2R4] - muon_hits_offsets[Lumi::Constants::M2R3];

    // M2R4
    ++muon_info_offset;
    parameters.dev_lumi_infos[muon_info_offset].size = LHCb::LumiSummaryOffsets::V2::MuonHitsM2R4Size;
    parameters.dev_lumi_infos[muon_info_offset].offset = LHCb::LumiSummaryOffsets::V2::MuonHitsM2R4Offset;
    parameters.dev_lumi_infos[muon_info_offset].value =
      muon_hits_offsets[Lumi::Constants::M3R1] - muon_hits_offsets[Lumi::Constants::M2R4];

    // M3R1
    ++muon_info_offset;
    parameters.dev_lumi_infos[muon_info_offset].size = LHCb::LumiSummaryOffsets::V2::MuonHitsM3R1Size;
    parameters.dev_lumi_infos[muon_info_offset].offset = LHCb::LumiSummaryOffsets::V2::MuonHitsM3R1Offset;
    parameters.dev_lumi_infos[muon_info_offset].value =
      muon_hits_offsets[Lumi::Constants::M3R2] - muon_hits_offsets[Lumi::Constants::M3R1];

    // M3R2
    ++muon_info_offset;
    parameters.dev_lumi_infos[muon_info_offset].size = LHCb::LumiSummaryOffsets::V2::MuonHitsM3R2Size;
    parameters.dev_lumi_infos[muon_info_offset].offset = LHCb::LumiSummaryOffsets::V2::MuonHitsM3R2Offset;
    parameters.dev_lumi_infos[muon_info_offset].value =
      muon_hits_offsets[Lumi::Constants::M3R3] - muon_hits_offsets[Lumi::Constants::M3R2];

    // M3R3
    ++muon_info_offset;
    parameters.dev_lumi_infos[muon_info_offset].size = LHCb::LumiSummaryOffsets::V2::MuonHitsM3R3Size;
    parameters.dev_lumi_infos[muon_info_offset].offset = LHCb::LumiSummaryOffsets::V2::MuonHitsM3R3Offset;
    parameters.dev_lumi_infos[muon_info_offset].value =
      muon_hits_offsets[Lumi::Constants::M3R4] - muon_hits_offsets[Lumi::Constants::M3R3];

    // M3R4
    ++muon_info_offset;
    parameters.dev_lumi_infos[muon_info_offset].size = LHCb::LumiSummaryOffsets::V2::MuonHitsM3R4Size;
    parameters.dev_lumi_infos[muon_info_offset].offset = LHCb::LumiSummaryOffsets::V2::MuonHitsM3R4Offset;
    parameters.dev_lumi_infos[muon_info_offset].value =
      muon_hits_offsets[Lumi::Constants::M4R1] - muon_hits_offsets[Lumi::Constants::M3R4];

    // M4R1
    ++muon_info_offset;
    parameters.dev_lumi_infos[muon_info_offset].size = LHCb::LumiSummaryOffsets::V2::MuonHitsM4R1Size;
    parameters.dev_lumi_infos[muon_info_offset].offset = LHCb::LumiSummaryOffsets::V2::MuonHitsM4R1Offset;
    parameters.dev_lumi_infos[muon_info_offset].value =
      muon_hits_offsets[Lumi::Constants::M4R2] - muon_hits_offsets[Lumi::Constants::M4R1];

    // M4R2
    ++muon_info_offset;
    parameters.dev_lumi_infos[muon_info_offset].size = LHCb::LumiSummaryOffsets::V2::MuonHitsM4R2Size;
    parameters.dev_lumi_infos[muon_info_offset].offset = LHCb::LumiSummaryOffsets::V2::MuonHitsM4R2Offset;
    parameters.dev_lumi_infos[muon_info_offset].value =
      muon_hits_offsets[Lumi::Constants::M4R3] - muon_hits_offsets[Lumi::Constants::M4R2];

    // M4R3
    ++muon_info_offset;
    parameters.dev_lumi_infos[muon_info_offset].size = LHCb::LumiSummaryOffsets::V2::MuonHitsM4R3Size;
    parameters.dev_lumi_infos[muon_info_offset].offset = LHCb::LumiSummaryOffsets::V2::MuonHitsM4R3Offset;
    parameters.dev_lumi_infos[muon_info_offset].value =
      muon_hits_offsets[Lumi::Constants::M4R4] - muon_hits_offsets[Lumi::Constants::M3R3];

    // M4R4
    ++muon_info_offset;
    parameters.dev_lumi_infos[muon_info_offset].size = LHCb::LumiSummaryOffsets::V2::MuonHitsM4R4Size;
    parameters.dev_lumi_infos[muon_info_offset].offset = LHCb::LumiSummaryOffsets::V2::MuonHitsM4R4Offset;
    parameters.dev_lumi_infos[muon_info_offset].value =
      muon_hits_offsets[Lumi::Constants::MuonBankSize] - muon_hits_offsets[Lumi::Constants::M4R4];
  }
}
