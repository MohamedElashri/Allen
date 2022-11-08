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
#include "LumiSummaryOffsets.h"

#include "CaloGeometry.cuh"

INSTANTIATE_ALGORITHM(calo_lumi_counters::calo_lumi_counters_t)

void calo_lumi_counters::calo_lumi_counters_t::set_arguments_size(
  ArgumentReferences<Parameters> arguments,
  const RuntimeOptions&,
  const Constants&) const
{
  set_size<dev_energies_t>(arguments, 12 * first<host_number_of_events_t>(arguments));
  // the total size of output info is proportional to the lumi summaries
  set_size<dev_lumi_infos_t>(
    arguments,
    Lumi::Constants::n_calo_counters * first<host_lumi_summaries_size_t>(arguments) / Lumi::Constants::lumi_length);
}

void calo_lumi_counters::calo_lumi_counters_t::init()
{
#ifndef ALLEN_STANDALONE
  std::map<int, std::string> area = {{0, "outer"}, {1, "middle"}, {2, "inner"}};

  m_histos_sum_et = std::make_unique<Gaudi::Accumulators::Histogram<1, Gaudi::Accumulators::atomicity::full, float>>(
    this, "sum_ET", "sum_ET", Gaudi::Accumulators::Axis<float> {100, 0., 100.f});

  for (int i = 0; i < 6; ++i) {
    std::string title = area[i % 3] + "_" + (i < 3 ? "top" : "bottom");
    m_histos_energy[i] =
      std::make_unique<Gaudi::Accumulators::Histogram<1, Gaudi::Accumulators::atomicity::full, float>>(
        this, "sum_E_" + title, "sum_E_" + title, Gaudi::Accumulators::Axis<float> {50, 0., 500.f});

    m_histos_et[i] = std::make_unique<Gaudi::Accumulators::Histogram<1, Gaudi::Accumulators::atomicity::full, float>>(
      this, "sum_ET_" + title, "sum_ET_" + title, Gaudi::Accumulators::Axis<float> {100, 0, 50.f});

    if (i < 3) {
      m_histos_energy_diff[i] =
        std::make_unique<Gaudi::Accumulators::Histogram<1, Gaudi::Accumulators::atomicity::full, float>>(
          this,
          "sum_E_diff_" + area[i % 3],
          "sum_E_diff_" + area[i % 3],
          Gaudi::Accumulators::Axis<float> {100, -100.f, 100.f});
      m_histos_et_diff[i] =
        std::make_unique<Gaudi::Accumulators::Histogram<1, Gaudi::Accumulators::atomicity::full, float>>(
          this,
          "sum_ET_diff_" + area[i % 3],
          "sum_ET_diff_" + area[i % 3],
          Gaudi::Accumulators::Axis<float> {40, -10.f, 10.f});
    }
  }
#endif
}

void calo_lumi_counters::calo_lumi_counters_t::operator()(
  const ArgumentReferences<Parameters>& arguments,
  const RuntimeOptions&,
  const Constants& constants,
  const Allen::Context& context) const
{
  // do nothing if no lumi event
  if (first<host_lumi_summaries_size_t>(arguments) == 0) return;

  Allen::memset_async<dev_energies_t>(arguments, 0, context);

  global_function(calo_lumi_counters)(dim3(2), property<block_dim_t>(), context)(
    arguments, first<host_number_of_events_t>(arguments), constants.dev_ecal_geometry);

#ifndef ALLEN_STANDALONE
  // Monitoring code
  if (!property<monitoring_t>()) return;

  auto energies = make_host_buffer<dev_energies_t>(arguments, context);
  auto offsets = make_host_buffer<dev_lumi_summary_offsets_t>(arguments, context);

  for (unsigned event_number = 0; event_number < first<host_number_of_events_t>(arguments); ++event_number) {

    unsigned lumi_sum_offset = offsets[event_number];

    // skip non-lumi event
    if (lumi_sum_offset == offsets[event_number + 1]) continue;

    auto* sum_e_area = energies.data() + event_number * 12;
    auto* sum_et_area = energies.data() + event_number * 12 + 6;

    auto sum_et = std::accumulate(sum_et_area, sum_et_area + 3, 0.f);
    ++(*m_histos_sum_et)[sum_et / 1000.f];

    for (int i = 0; i < 6; ++i) {
      if (i < 3) {
        ++(*m_histos_energy_diff[i])[(sum_e_area[i] - sum_e_area[i + 3]) / 1000.f];
        ++(*m_histos_et_diff[i])[(sum_et_area[i] - sum_et_area[i + 3]) / 1000.f];
      }
      ++(*m_histos_energy[i])[sum_e_area[i] / 1000.f];
      ++(*m_histos_et[i])[sum_et_area[i] / 1000.f];
    }
  }
#endif
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
    float sum_et = 0.f;
    float sum_e = 0.f;
    auto* sum_e_area = parameters.dev_energies + event_number * 12;
    auto* sum_et_area = parameters.dev_energies + event_number * 12 + 6;

    for (unsigned digit_index = 0u; digit_index < n_digits; ++digit_index) {
      if (!digits[digit_index].is_valid()) continue;

      auto x = ecal_geometry.getX(digit_index);
      auto y = ecal_geometry.getY(digit_index);
      // Use Z at shower max
      auto z = ecal_geometry.getZ(digit_index, 1);
      auto e = ecal_geometry.getE(digit_index, digits[digit_index].adc);

      auto sin_theta = sqrtf((x * x + y * y) / (x * x + y * y + z * z));

      sum_e += e;
      sum_et += e * sin_theta;

      auto const area = ecal_geometry.getECALArea(digit_index);
      if (y > 0.f) {
        sum_e_area[area] += e;
        sum_et_area[area] += e * sin_theta;
      }
      else {
        sum_e_area[3 + area] += e;
        sum_et_area[3 + area] += e * sin_theta;
      }
    }

    unsigned info_offset = Lumi::Constants::n_calo_counters * lumi_sum_offset / Lumi::Constants::lumi_length;

    parameters.dev_lumi_infos[info_offset].offset = LHCb::LumiSummaryOffsets::V2::ECalETOffset;
    parameters.dev_lumi_infos[info_offset].size = LHCb::LumiSummaryOffsets::V2::ECalETSize;
    parameters.dev_lumi_infos[info_offset].value = sum_et;

    // Outer Top
    ++info_offset;
    parameters.dev_lumi_infos[info_offset].offset = LHCb::LumiSummaryOffsets::V2::ECalEOuterTopOffset;
    parameters.dev_lumi_infos[info_offset].size = LHCb::LumiSummaryOffsets::V2::ECalEOuterTopSize;
    parameters.dev_lumi_infos[info_offset].value = sum_et_area[0];

    // Middle Top
    ++info_offset;
    parameters.dev_lumi_infos[info_offset].offset = LHCb::LumiSummaryOffsets::V2::ECalEMiddleTopOffset;
    parameters.dev_lumi_infos[info_offset].size = LHCb::LumiSummaryOffsets::V2::ECalEMiddleTopSize;
    parameters.dev_lumi_infos[info_offset].value = sum_et_area[1];

    // Inner Top
    ++info_offset;
    parameters.dev_lumi_infos[info_offset].offset = LHCb::LumiSummaryOffsets::V2::ECalEInnerTopOffset;
    parameters.dev_lumi_infos[info_offset].size = LHCb::LumiSummaryOffsets::V2::ECalEInnerTopSize;
    parameters.dev_lumi_infos[info_offset].value = sum_et_area[2];

    // Outer Bottom
    ++info_offset;
    parameters.dev_lumi_infos[info_offset].offset = LHCb::LumiSummaryOffsets::V2::ECalEOuterBottomOffset;
    parameters.dev_lumi_infos[info_offset].size = LHCb::LumiSummaryOffsets::V2::ECalEOuterBottomSize;
    parameters.dev_lumi_infos[info_offset].value = sum_et_area[3];

    // Middle Bottom
    ++info_offset;
    parameters.dev_lumi_infos[info_offset].offset = LHCb::LumiSummaryOffsets::V2::ECalEMiddleBottomOffset;
    parameters.dev_lumi_infos[info_offset].size = LHCb::LumiSummaryOffsets::V2::ECalEMiddleBottomSize;
    parameters.dev_lumi_infos[info_offset].value = sum_et_area[4];

    // Inner Bottom
    ++info_offset;
    parameters.dev_lumi_infos[info_offset].offset = LHCb::LumiSummaryOffsets::V2::ECalEInnerBottomOffset;
    parameters.dev_lumi_infos[info_offset].size = LHCb::LumiSummaryOffsets::V2::ECalEInnerBottomSize;
    parameters.dev_lumi_infos[info_offset].value = sum_et_area[5];
  }
}
