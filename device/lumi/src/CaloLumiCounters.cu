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
  std::map<std::string, std::pair<unsigned, unsigned>> schema = m_lumi_counter_schema;
  std::map<std::string, std::pair<float, float>> shifts_and_scales = m_lumi_counter_shifts_and_scales;

  unsigned c_idx = 0u;
  for (auto counter_name : Lumi::Constants::calo_counter_names) {
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

void calo_lumi_counters::calo_lumi_counters_t::operator()(
  const ArgumentReferences<Parameters>& arguments,
  const RuntimeOptions&,
  const Constants& constants,
  const Allen::Context& context) const
{
  // do nothing if no lumi event
  if (first<host_lumi_summaries_count_t>(arguments) == 0) return;

  Allen::memset_async<dev_lumi_infos_t>(arguments, 0, context);

  global_function(calo_lumi_counters)(dim3(first<host_number_of_events_t>(arguments)), m_block_dim, context)(
    arguments, m_offsets_and_sizes, m_shifts_and_scales, constants.dev_ecal_geometry);
}

__global__ void calo_lumi_counters::calo_lumi_counters(
  calo_lumi_counters::Parameters parameters,
  const offsets_and_sizes_t offsets_and_sizes,
  const shifts_and_scales_t shifts_and_scales,
  const char* raw_ecal_geometry)
{
  unsigned event_number = blockIdx.x;
  unsigned lumi_evt_index = parameters.dev_lumi_event_indices[event_number];

  // skip non-lumi event
  if (lumi_evt_index == parameters.dev_lumi_event_indices[event_number + 1]) return;

  auto ecal_geometry = CaloGeometry(raw_ecal_geometry);
  const unsigned digits_offset = parameters.dev_ecal_digits_offsets[event_number];
  const unsigned n_digits = parameters.dev_ecal_digits_offsets[event_number + 1] - digits_offset;
  auto const* digits = parameters.dev_ecal_digits + digits_offset;
  // first 2 reserved for sum et and sum e, followed by ET for each region
  __shared__ unsigned long long
    E_vals[Lumi::Constants::n_calo_counters * 2]; // positive and negative separately. result for counter i will be
                                                  // value at (2 * i) - value at  (2 * i + 1)

  for (unsigned i = threadIdx.x; i < Lumi::Constants::n_calo_counters * 2; i += blockDim.x) {
    E_vals[i] = 0;
  }

  __syncthreads();

  for (unsigned digit_index = threadIdx.x; digit_index < n_digits; digit_index += blockDim.x) {
    if (!digits[digit_index].is_valid()) continue;

    auto x = ecal_geometry.getX(digit_index);
    auto y = ecal_geometry.getY(digit_index);
    // Use Z at shower max
    auto z = ecal_geometry.getZ(digit_index, 1);
    auto e = ecal_geometry.getE(digit_index, digits[digit_index].adc);

    auto sin_theta = sqrtf((x * x + y * y) / (x * x + y * y + z * z));

    auto e_abs = fabsf(e);

    auto e_negative = e < 0.f;

    atomicAdd(&E_vals[0] + e_negative, static_cast<unsigned long long>(e_abs * sin_theta * 1e8f));
    atomicAdd(&E_vals[2] + e_negative, static_cast<unsigned long long>(e_abs * 1e8f));

    auto const area = ecal_geometry.getECALArea(digit_index);
    if (y > 0.f) {
      atomicAdd(&E_vals[2 * (2 + area) + e_negative], static_cast<unsigned long long>(e_abs * sin_theta * 1e8f));
    }
    else {
      atomicAdd(&E_vals[2 * (5 + area) + e_negative], static_cast<unsigned long long>(e_abs * sin_theta * 1e8f));
    }
  }

  __syncthreads();
  unsigned info_offset = Lumi::Constants::n_calo_counters * lumi_evt_index;

  for (unsigned i = threadIdx.x; i < Lumi::Constants::n_calo_counters; i += blockDim.x) {
    fillLumiInfo(
      parameters.dev_lumi_infos[info_offset + i],
      offsets_and_sizes[2 * i],
      offsets_and_sizes[2 * i + 1],
      (static_cast<float>(E_vals[2 * i]) - static_cast<float>(E_vals[2 * i + 1])) / 1e8f,
      shifts_and_scales[2 * i],
      shifts_and_scales[2 * i + 1]);
  }
}
