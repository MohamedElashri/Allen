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
  std::array<unsigned, 2 * Lumi::Constants::n_calo_counters> calo_offsets_and_sizes =
    property<calo_offsets_and_sizes_t>();

  unsigned c_idx(0u);
  for (auto counter_name : Lumi::Constants::calo_counter_names) {
    if (schema.find(counter_name) == schema.end()) {
      std::cout << "LumiSummary schema does not use " << counter_name << std::endl;
    }
    else {
      calo_offsets_and_sizes[2 * c_idx] = schema[counter_name].first;
      calo_offsets_and_sizes[2 * c_idx + 1] = schema[counter_name].second;
    }
    ++c_idx;
  }
  set_property_value<calo_offsets_and_sizes_t>(calo_offsets_and_sizes);
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
    // sumET followed by Etot for each region
    std::array<float, Lumi::Constants::n_calo_counters> E_vals = {0.f, 0.f, 0.f, 0.f, 0.f, 0.f, 0.f};

    for (unsigned digit_index = 0u; digit_index < n_digits; ++digit_index) {
      float x(0.f), y(0.f), z(0.f), e(0.f);
      x = ecal_geometry.getX(digit_index);
      y = ecal_geometry.getY(digit_index);
      z = (ecal_geometry.getZ(digit_index, 0) + ecal_geometry.getZ(digit_index, 2)) / 2.f;
      e = ecal_geometry.getE(digit_index, digits[digit_index].adc);

      E_vals[0] += e * sqrtf((x * x + y * y) / (x * x + y * y + z * z));

      if (y > 0.f) {
        E_vals[1 + ecal_geometry.getECALArea(digit_index)] += e;
      }
      else {
        E_vals[4 + ecal_geometry.getECALArea(digit_index)] += e;
      }
    }

    unsigned info_offset = Lumi::Constants::n_calo_counters * lumi_sum_offset / parameters.lumi_sum_length;

    for (unsigned i = 0; i < Lumi::Constants::n_calo_counters; ++i) {
      fillLumiInfo(
        parameters.dev_lumi_infos[info_offset + i],
        parameters.calo_offsets_and_sizes.get()[2 * i],
        parameters.calo_offsets_and_sizes.get()[2 * i + 1],
        E_vals[i]);
    }
  }
}
