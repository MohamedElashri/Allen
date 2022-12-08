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
  // convert the size of lumi summaries to the size of muon counter infos
  set_size<dev_lumi_infos_t>(
    arguments,
    Lumi::Constants::n_muon_counters * first<host_lumi_summaries_size_t>(arguments) / property<lumi_sum_length_t>());
}

void muon_lumi_counters::muon_lumi_counters_t::init()
{
  std::map<std::string, std::pair<unsigned, unsigned>> schema = property<lumi_counter_schema_t>();

  if (schema.find("MuonHitsM2R1") == schema.end()) {
    std::cout << "LumiSummary schema does not use MuonHitsM2R1" << std::endl;
  }
  else {
    set_property_value<muon_hits_m2r1_offset_and_size_t>(schema["MuonHitsM2R1"]);
  }

  if (schema.find("MuonHitsM2R2") == schema.end()) {
    std::cout << "LumiSummary schema does not use MuonHitsM2R2" << std::endl;
  }
  else {
    set_property_value<muon_hits_m2r2_offset_and_size_t>(schema["MuonHitsM2R2"]);
  }

  if (schema.find("MuonHitsM2R3") == schema.end()) {
    std::cout << "LumiSummary schema does not use MuonHitsM2R3" << std::endl;
  }
  else {
    set_property_value<muon_hits_m2r3_offset_and_size_t>(schema["MuonHitsM2R3"]);
  }

  if (schema.find("MuonHitsM2R4") == schema.end()) {
    std::cout << "LumiSummary schema does not use MuonHitsM2R4" << std::endl;
  }
  else {
    set_property_value<muon_hits_m2r4_offset_and_size_t>(schema["MuonHitsM2R4"]);
  }

  if (schema.find("MuonHitsM3R1") == schema.end()) {
    std::cout << "LumiSummary schema does not use MuonHitsM3R1" << std::endl;
  }
  else {
    set_property_value<muon_hits_m3r1_offset_and_size_t>(schema["MuonHitsM3R1"]);
  }

  if (schema.find("MuonHitsM3R2") == schema.end()) {
    std::cout << "LumiSummary schema does not use MuonHitsM3R2" << std::endl;
  }
  else {
    set_property_value<muon_hits_m3r2_offset_and_size_t>(schema["MuonHitsM3R2"]);
  }

  if (schema.find("MuonHitsM3R3") == schema.end()) {
    std::cout << "LumiSummary schema does not use MuonHitsM3R3" << std::endl;
  }
  else {
    set_property_value<muon_hits_m3r3_offset_and_size_t>(schema["MuonHitsM3R3"]);
  }

  if (schema.find("MuonHitsM3R4") == schema.end()) {
    std::cout << "LumiSummary schema does not use MuonHitsM3R4" << std::endl;
  }
  else {
    set_property_value<muon_hits_m3r4_offset_and_size_t>(schema["MuonHitsM3R4"]);
  }

  if (schema.find("MuonHitsM4R1") == schema.end()) {
    std::cout << "LumiSummary schema does not use MuonHitsM4R1" << std::endl;
  }
  else {
    set_property_value<muon_hits_m4r1_offset_and_size_t>(schema["MuonHitsM4R1"]);
  }

  if (schema.find("MuonHitsM4R2") == schema.end()) {
    std::cout << "LumiSummary schema does not use MuonHitsM4R2" << std::endl;
  }
  else {
    set_property_value<muon_hits_m4r2_offset_and_size_t>(schema["MuonHitsM4R2"]);
  }

  if (schema.find("MuonHitsM4R3") == schema.end()) {
    std::cout << "LumiSummary schema does not use MuonHitsM4R3" << std::endl;
  }
  else {
    set_property_value<muon_hits_m4r3_offset_and_size_t>(schema["MuonHitsM4R3"]);
  }

  if (schema.find("MuonHitsM4R4") == schema.end()) {
    std::cout << "LumiSummary schema does not use MuonHitsM4R4" << std::endl;
  }
  else {
    set_property_value<muon_hits_m4r4_offset_and_size_t>(schema["MuonHitsM4R4"]);
  }
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

    unsigned muon_info_offset = 12u * lumi_sum_offset / parameters.lumi_sum_length;
    // M2R1
    fillLumiInfo(parameters.dev_lumi_infos[muon_info_offset],
                 parameters.muon_hits_m2r1_offset_and_size,
                 muon_hits_offsets[Lumi::Constants::M2R2] - muon_hits_offsets[Lumi::Constants::M2R1]);

    // M2R2
    fillLumiInfo(parameters.dev_lumi_infos[muon_info_offset+1],
                 parameters.muon_hits_m2r2_offset_and_size,
                 muon_hits_offsets[Lumi::Constants::M2R3] - muon_hits_offsets[Lumi::Constants::M2R2]);

    // M2R3
    fillLumiInfo(parameters.dev_lumi_infos[muon_info_offset+2],
                 parameters.muon_hits_m2r3_offset_and_size,
                 muon_hits_offsets[Lumi::Constants::M2R4] - muon_hits_offsets[Lumi::Constants::M2R3]);

    // M2R4
    fillLumiInfo(parameters.dev_lumi_infos[muon_info_offset+3],
                 parameters.muon_hits_m2r4_offset_and_size,
                 muon_hits_offsets[Lumi::Constants::M3R1] - muon_hits_offsets[Lumi::Constants::M2R4]);

    // M3R1
    fillLumiInfo(parameters.dev_lumi_infos[muon_info_offset+4],
                 parameters.muon_hits_m3r1_offset_and_size,
                 muon_hits_offsets[Lumi::Constants::M3R2] - muon_hits_offsets[Lumi::Constants::M3R1]);

    // M3R2
    fillLumiInfo(parameters.dev_lumi_infos[muon_info_offset+5],
                 parameters.muon_hits_m3r2_offset_and_size,
                 muon_hits_offsets[Lumi::Constants::M3R3] - muon_hits_offsets[Lumi::Constants::M3R2]);

    // M3R3
    fillLumiInfo(parameters.dev_lumi_infos[muon_info_offset+6],
                 parameters.muon_hits_m3r3_offset_and_size,
                 muon_hits_offsets[Lumi::Constants::M3R4] - muon_hits_offsets[Lumi::Constants::M3R3]);

    // M3R4
    fillLumiInfo(parameters.dev_lumi_infos[muon_info_offset+7],
                 parameters.muon_hits_m3r4_offset_and_size,
                 muon_hits_offsets[Lumi::Constants::M4R1] - muon_hits_offsets[Lumi::Constants::M3R4]);

    // M4R1
    fillLumiInfo(parameters.dev_lumi_infos[muon_info_offset+8],
                 parameters.muon_hits_m4r1_offset_and_size,
                 muon_hits_offsets[Lumi::Constants::M4R2] - muon_hits_offsets[Lumi::Constants::M4R1]);

    // M4R2
    fillLumiInfo(parameters.dev_lumi_infos[muon_info_offset+9],
                 parameters.muon_hits_m4r2_offset_and_size,
                 muon_hits_offsets[Lumi::Constants::M4R3] - muon_hits_offsets[Lumi::Constants::M4R2]);

    // M4R3
    fillLumiInfo(parameters.dev_lumi_infos[muon_info_offset+10],
                 parameters.muon_hits_m4r3_offset_and_size,
                 muon_hits_offsets[Lumi::Constants::M4R4] - muon_hits_offsets[Lumi::Constants::M4R3]);

    // M4R4
    fillLumiInfo(parameters.dev_lumi_infos[muon_info_offset+11],
                 parameters.muon_hits_m4r4_offset_and_size,
                 muon_hits_offsets[Lumi::Constants::MuonBankSize] - muon_hits_offsets[Lumi::Constants::M4R4]);
  }
}
