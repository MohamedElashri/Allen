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
#include <Event/LumiSummaryOffsets_V2.h>

#include "CaloGeometry.cuh"

INSTANTIATE_ALGORITHM(calo_lumi_counters::calo_lumi_counters_t)

void calo_lumi_counters::calo_lumi_counters_t::set_arguments_size(
  ArgumentReferences<Parameters> arguments,
  const RuntimeOptions&,
  const Constants&,
  const HostBuffers&) const
{
  // convert the size of lumi summaries to the size of velo counter infos
  set_size<dev_lumi_infos_t>(
    arguments,
    Lumi::Constants::n_calo_counters * first<host_lumi_summaries_size_t>(arguments) / Lumi::Constants::lumi_length);
}

void calo_lumi_counters::calo_lumi_counters_t::operator()(
  const ArgumentReferences<Parameters>& arguments,
  const RuntimeOptions&,
  const Constants& constants,
  HostBuffers&,
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

    unsigned info_offset = 7u * lumi_sum_offset / Lumi::Constants::lumi_length;

    parameters.dev_lumi_infos[info_offset].offset = LHCb::LumiSummaryOffsets::V2::ECalETOffset;
    parameters.dev_lumi_infos[info_offset].size = LHCb::LumiSummaryOffsets::V2::ECalETSize;
    parameters.dev_lumi_infos[info_offset].value = sumET;

    // Outer Top
    ++info_offset;
    parameters.dev_lumi_infos[info_offset].offset = LHCb::LumiSummaryOffsets::V2::ECalEOuterTopOffset;
    parameters.dev_lumi_infos[info_offset].size = LHCb::LumiSummaryOffsets::V2::ECalEOuterTopSize;
    parameters.dev_lumi_infos[info_offset].value = Etot[0];

    // Middle Top
    ++info_offset;
    parameters.dev_lumi_infos[info_offset].offset = LHCb::LumiSummaryOffsets::V2::ECalEMiddleTopOffset;
    parameters.dev_lumi_infos[info_offset].size = LHCb::LumiSummaryOffsets::V2::ECalEMiddleTopSize;
    parameters.dev_lumi_infos[info_offset].value = Etot[1];

    // Inner Top
    ++info_offset;
    parameters.dev_lumi_infos[info_offset].offset = LHCb::LumiSummaryOffsets::V2::ECalEInnerTopOffset;
    parameters.dev_lumi_infos[info_offset].size = LHCb::LumiSummaryOffsets::V2::ECalEInnerTopSize;
    parameters.dev_lumi_infos[info_offset].value = Etot[2];

    // Outer Bottom
    ++info_offset;
    parameters.dev_lumi_infos[info_offset].offset = LHCb::LumiSummaryOffsets::V2::ECalEOuterBottomOffset;
    parameters.dev_lumi_infos[info_offset].size = LHCb::LumiSummaryOffsets::V2::ECalEOuterBottomSize;
    parameters.dev_lumi_infos[info_offset].value = Etot[3];

    // Middle Bottom
    ++info_offset;
    parameters.dev_lumi_infos[info_offset].offset = LHCb::LumiSummaryOffsets::V2::ECalEMiddleBottomOffset;
    parameters.dev_lumi_infos[info_offset].size = LHCb::LumiSummaryOffsets::V2::ECalEMiddleBottomSize;
    parameters.dev_lumi_infos[info_offset].value = Etot[4];

    // Inner Bottom
    ++info_offset;
    parameters.dev_lumi_infos[info_offset].offset = LHCb::LumiSummaryOffsets::V2::ECalEInnerBottomOffset;
    parameters.dev_lumi_infos[info_offset].size = LHCb::LumiSummaryOffsets::V2::ECalEInnerBottomSize;
    parameters.dev_lumi_infos[info_offset].value = Etot[5];
  }
}
