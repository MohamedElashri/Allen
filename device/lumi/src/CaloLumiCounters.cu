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
#include "CaloLumiCounters.cuh"
#include "LumiCommon.cuh"

#include "CaloGeometry.cuh"

INSTANTIATE_ALGORITHM(calo_lumi_counters::calo_lumi_counters_t)

void calo_lumi_counters::calo_lumi_counters_t::set_arguments_size(
  ArgumentReferences<Parameters> arguments,
  const RuntimeOptions&,
  const Constants&) const
{
  // convert the size of lumi summaries to the size of velo counter infos
  set_size<dev_lumi_infos_t>(
    arguments,
    Lumi::Constants::n_calo_counters * first<host_lumi_summaries_size_t>(arguments) / property<lumi_sum_length_t>());
}

void calo_lumi_counters::calo_lumi_counters_t::init()
{
  std::map<std::string, std::pair<unsigned, unsigned>> schema = property<lumi_counter_schema_t>();

  if (schema.find("ECalET") == schema.end()) {
    std::cout << "LumiSummary schema does not use ECalET" << std::endl;
  }
  else {
    set_property_value<ecal_et_offset_and_size_t>(schema["ECalET"]);
  }

  if (schema.find("ECalEOuterTop") == schema.end()) {
    std::cout << "LumiSummary schema does not use ECalEOuterTop" << std::endl;
  }
  else {
    set_property_value<ecal_e_outer_top_offset_and_size_t>(schema["ECalEOuterTop"]);
  }

  if (schema.find("ECalEMiddleTop") == schema.end()) {
    std::cout << "LumiSummary schema does not use ECalEMiddleTop" << std::endl;
  }
  else {
    set_property_value<ecal_e_middle_top_offset_and_size_t>(schema["ECalEMiddleTop"]);
  }

  if (schema.find("ECalEInnerTop") == schema.end()) {
    std::cout << "LumiSummary schema does not use ECalEInnerTop" << std::endl;
  }
  else {
    set_property_value<ecal_e_inner_top_offset_and_size_t>(schema["ECalEInnerTop"]);
  }

  if (schema.find("ECalEOuterBottom") == schema.end()) {
    std::cout << "LumiSummary schema does not use ECalEOuterBottom" << std::endl;
  }
  else {
    set_property_value<ecal_e_outer_bottom_offset_and_size_t>(schema["ECalEOuterBottom"]);
  }

  if (schema.find("ECalEMiddleBottom") == schema.end()) {
    std::cout << "LumiSummary schema does not use ECalEMiddleBottom" << std::endl;
  }
  else {
    set_property_value<ecal_e_middle_bottom_offset_and_size_t>(schema["ECalEMiddleBottom"]);
  }

  if (schema.find("ECalEInnerBottom") == schema.end()) {
    std::cout << "LumiSummary schema does not use ECalEInnerBottom" << std::endl;
  }
  else {
    set_property_value<ecal_e_inner_bottom_offset_and_size_t>(schema["ECalEInnerBottom"]);
  }
}

void calo_lumi_counters::calo_lumi_counters_t::operator()(
  const ArgumentReferences<Parameters>& arguments,
  const RuntimeOptions&,
  const Constants& constants,
  const Allen::Context& context) const
{
  // do nothing if no lumi event
  if (first<host_lumi_summaries_size_t>(arguments) == 0) return;

  global_function(calo_lumi_counters)(
    dim3(first<host_number_of_events_t>(arguments)), property<block_dim_t>(), context)(
    arguments, first<host_number_of_events_t>(arguments), constants.dev_ecal_geometry);
}

__global__ void calo_lumi_counters::calo_lumi_counters(
  calo_lumi_counters::Parameters parameters,
  const unsigned number_of_events,
  const char* raw_ecal_geometry)
{
  for (unsigned event_number = blockIdx.x * blockDim.x + threadIdx.x; event_number < number_of_events;
       event_number += blockDim.x * gridDim.x) {
    unsigned lumi_sum_offset = parameters.dev_lumi_summary_offsets[event_number];

    // skip non-lumi event
    if (lumi_sum_offset == parameters.dev_lumi_summary_offsets[event_number + 1]) continue;

    auto ecal_geometry = CaloGeometry(raw_ecal_geometry);
    const unsigned digits_offset = parameters.dev_ecal_digits_offsets[event_number];
    const unsigned n_digits = parameters.dev_ecal_digits_offsets[event_number + 1] - digits_offset;
    auto const* digits = parameters.dev_ecal_digits + digits_offset;
    float sumET = 0.f;
    std::array<float, 6> Etot = {0.f, 0.f, 0.f, 0.f, 0.f, 0.f};

    for (unsigned digit_index = 0u; digit_index < n_digits; ++digit_index) {
      float x(0.f), y(0.f), z(0.f), e(0.f);
      x = ecal_geometry.getX(digit_index);
      y = ecal_geometry.getY(digit_index);
      z = (ecal_geometry.getZ(digit_index, 0) + ecal_geometry.getZ(digit_index, 2)) / 2.f;
      e = ecal_geometry.getE(digit_index, digits[digit_index].adc);

      sumET += e * sqrtf((x * x + y * y) / (x * x + y * y + z * z));

      if (y > 0.f) {
        Etot[ecal_geometry.getECALArea(digit_index)] += e;
      }
      else {
        Etot[3 + ecal_geometry.getECALArea(digit_index)] += e;
      }
    }

    unsigned info_offset = 7u * lumi_sum_offset / parameters.lumi_sum_length;

    fillLumiInfo(parameters.dev_lumi_infos[info_offset],
                 parameters.ecal_et_offset_and_size,
                 sumET);

    // Outer Top
    fillLumiInfo(parameters.dev_lumi_infos[info_offset+1],
                 parameters.ecal_e_outer_top_offset_and_size,
                 Etot[0]);

    // Middle Top
    fillLumiInfo(parameters.dev_lumi_infos[info_offset+2],
                 parameters.ecal_e_middle_top_offset_and_size,
                 Etot[1]);

    // Inner Top
    fillLumiInfo(parameters.dev_lumi_infos[info_offset+3],
                 parameters.ecal_e_inner_top_offset_and_size,
                 Etot[2]);

    // Outer Bottom
    fillLumiInfo(parameters.dev_lumi_infos[info_offset+4],
                 parameters.ecal_e_outer_bottom_offset_and_size,
                 Etot[3]);

    // Middle Bottom
    fillLumiInfo(parameters.dev_lumi_infos[info_offset+5],
                 parameters.ecal_e_middle_bottom_offset_and_size,
                 Etot[4]);

    // Inner Bottom
    fillLumiInfo(parameters.dev_lumi_infos[info_offset+6],
                 parameters.ecal_e_inner_bottom_offset_and_size,
                 Etot[5]);
  }
}
