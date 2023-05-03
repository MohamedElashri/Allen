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
  // the total size of output info is proportional to the lumi summaries
  set_size<dev_lumi_infos_t>(
    arguments, Lumi::Constants::n_calo_counters * first<host_lumi_summaries_count_t>(arguments));
}

void calo_lumi_counters::calo_lumi_counters_t::init()
{
  std::map<std::string, std::pair<unsigned, unsigned>> schema = property<lumi_counter_schema_t>();
  std::map<std::string, std::pair<float, float>> shifts_and_scales = property<lumi_counter_shifts_and_scales_t>();
  std::array<unsigned, 2 * Lumi::Constants::n_calo_counters> calo_offsets_and_sizes =
    property<calo_offsets_and_sizes_t>();
  std::array<float, 2 * Lumi::Constants::n_calo_counters> calo_shifts_and_scales = property<calo_shifts_and_scales_t>();

  unsigned c_idx(0u);
  for (auto counter_name : Lumi::Constants::calo_counter_names) {
    if (schema.find(counter_name) == schema.end()) {
      std::cout << "LumiSummary schema does not use " << counter_name << std::endl;
    }
    else {
      calo_offsets_and_sizes[2 * c_idx] = schema[counter_name].first;
      calo_offsets_and_sizes[2 * c_idx + 1] = schema[counter_name].second;
    }
    if (shifts_and_scales.find(counter_name) == shifts_and_scales.end()) {
      calo_shifts_and_scales[2 * c_idx] = 0.f;
      calo_shifts_and_scales[2 * c_idx + 1] = 1.f;
    }
    else {
      calo_shifts_and_scales[2 * c_idx] = shifts_and_scales[counter_name].first;
      calo_shifts_and_scales[2 * c_idx + 1] = shifts_and_scales[counter_name].second;
    }
    ++c_idx;
  }
  set_property_value<calo_offsets_and_sizes_t>(calo_offsets_and_sizes);
  set_property_value<calo_shifts_and_scales_t>(calo_shifts_and_scales);
}

void calo_lumi_counters::calo_lumi_counters_t::operator()(
  const ArgumentReferences<Parameters>& arguments,
  const RuntimeOptions&,
  const Constants& constants,
  const Allen::Context& context) const
{
  // do nothing if no lumi event
  if (first<host_lumi_summaries_count_t>(arguments) == 0) return;

  global_function(calo_lumi_counters)(dim3(2), property<block_dim_t>(), context)(
    arguments, first<host_number_of_events_t>(arguments), constants.dev_ecal_geometry);
}

__global__ void calo_lumi_counters::calo_lumi_counters(
  calo_lumi_counters::Parameters parameters,
  const unsigned number_of_events,
  const char* raw_ecal_geometry)
{
  for (unsigned event_number = blockIdx.x * blockDim.x + threadIdx.x; event_number < number_of_events;
       event_number += blockDim.x * gridDim.x) {
    unsigned lumi_evt_index = parameters.dev_lumi_event_indices[event_number];

    // skip non-lumi event
    if (lumi_evt_index == parameters.dev_lumi_event_indices[event_number + 1]) continue;

    auto ecal_geometry = CaloGeometry(raw_ecal_geometry);
    const unsigned digits_offset = parameters.dev_ecal_digits_offsets[event_number];
    const unsigned n_digits = parameters.dev_ecal_digits_offsets[event_number + 1] - digits_offset;
    auto const* digits = parameters.dev_ecal_digits + digits_offset;
    // first 2 reserved for sum et and sum e, followed by ET for each region
    std::array<float, Lumi::Constants::n_calo_counters> E_vals = {0.f, 0.f, 0.f, 0.f, 0.f, 0.f, 0.f, 0.f};

    for (unsigned digit_index = 0u; digit_index < n_digits; ++digit_index) {
      if (!digits[digit_index].is_valid()) continue;

      auto x = ecal_geometry.getX(digit_index);
      auto y = ecal_geometry.getY(digit_index);
      // Use Z at shower max
      auto z = ecal_geometry.getZ(digit_index, 1);
      auto e = ecal_geometry.getE(digit_index, digits[digit_index].adc);

      auto sin_theta = sqrtf((x * x + y * y) / (x * x + y * y + z * z));
      E_vals[0] += e * sin_theta;
      E_vals[1] += e;

      auto const area = ecal_geometry.getECALArea(digit_index);
      if (y > 0.f) {
        E_vals[2 + area] += e * sin_theta;
      }
      else {
        E_vals[5 + area] += e * sin_theta;
      }
    }

    unsigned info_offset = Lumi::Constants::n_calo_counters * lumi_evt_index;

    for (unsigned i = 0; i < Lumi::Constants::n_calo_counters; ++i) {
      fillLumiInfo(
        parameters.dev_lumi_infos[info_offset + i],
        parameters.calo_offsets_and_sizes.get()[2 * i],
        parameters.calo_offsets_and_sizes.get()[2 * i + 1],
        E_vals[i],
        parameters.calo_shifts_and_scales.get()[2 * i],
        parameters.calo_shifts_and_scales.get()[2 * i + 1]);
    }
  }
}
