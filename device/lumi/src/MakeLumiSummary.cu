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
#include "MakeLumiSummary.cuh"
#include "LumiCounterOffsets.h"

#include "SelectionsEventModel.cuh"
#include "Event/ODIN.h"

#include "SciFiDefinitions.cuh"

INSTANTIATE_ALGORITHM(make_lumi_summary::make_lumi_summary_t)

void make_lumi_summary::make_lumi_summary_t::set_arguments_size(
  ArgumentReferences<Parameters> arguments,
  const RuntimeOptions&,
  const Constants&,
  const HostBuffers&) const
{
  // to avoid warning massage from MemoryManager
  // if no lumi event, set lumi_sum_sizes = 1u
  if (first<host_lumi_summaries_size_t>(arguments) == 0)
    set_size<dev_lumi_summaries_t>(arguments, 1u);
  else
    set_size<dev_lumi_summaries_t>(arguments, first<host_lumi_summaries_size_t>(arguments));
}

void make_lumi_summary::make_lumi_summary_t::operator()(
  const ArgumentReferences<Parameters>& arguments,
  const RuntimeOptions&,
  const Constants&,
  HostBuffers& host_buffers,
  const Allen::Context& context) const
{
  // do nothing if no lumi event
  if (first<host_lumi_summaries_size_t>(arguments) == 0) {
    Allen::copy_async<dev_lumi_summary_offsets_t>(host_buffers.host_lumi_summary_offsets, arguments, context);
    Allen::copy_async<dev_lumi_summaries_t>(host_buffers.host_lumi_summaries, arguments, context);
    return;
  }

  Allen::memset_async<dev_lumi_summaries_t>(arguments, 0, context);

  global_function(make_lumi_summary)(dim3(first<host_number_of_events_t>(arguments)), property<block_dim_t>(), context)(
    arguments, first<host_number_of_events_t>(arguments), size<dev_event_list_t>(arguments));

  Allen::copy_async<dev_lumi_summary_offsets_t>(host_buffers.host_lumi_summary_offsets, arguments, context);
  Allen::copy_async<dev_lumi_summaries_t>(host_buffers.host_lumi_summaries, arguments, context);
}

__device__ void make_lumi_summary::setField(
  Allen::LumiCounterOffsets::counterOffset offset,
  Allen::LumiCounterOffsets::counterOffset size,
  unsigned* target,
  unsigned value)
{
  // Check value fits within size bits
  if (size < (8 * sizeof(unsigned)) && value >= (1u << size)) {
    return;
  }

  // Separate offset into a word part and bit part
  unsigned word = offset / (8 * sizeof(unsigned));
  unsigned bitoffset = offset % (8 * sizeof(unsigned));

  // Check size and offset line up with word boundaries
  if (bitoffset + size > (8 * sizeof(unsigned))) {
    return;
  }

  // Apply the value to the matching bits
  unsigned mask = ((1 << size) - 1) << bitoffset;
  target[word] = (target[word] & ~mask) | ((value << bitoffset) & mask);
}

__global__ void make_lumi_summary::make_lumi_summary(
  make_lumi_summary::Parameters parameters,
  const unsigned number_of_events,
  const unsigned number_of_events_passed_gec)
{
  for (unsigned event_number = blockIdx.x * blockDim.x + threadIdx.x; event_number < number_of_events;
       event_number += blockDim.x * gridDim.x) {
    unsigned offset = parameters.dev_lumi_summary_offsets[event_number];

    // skip non-lumi event
    if (offset == parameters.dev_lumi_summary_offsets[event_number + 1]) continue;

    const auto lumi_summary = parameters.dev_lumi_summaries + offset;
    /// ODIN information
    const LHCb::ODIN odin {parameters.dev_odin_data[event_number]};
    uint64_t new_bcid = static_cast<uint32_t>(odin.orbitNumber()) * 3564 + static_cast<uint16_t>(odin.bunchId());
    uint64_t t0 = static_cast<uint64_t>(odin.gpsTime()) - new_bcid * 1000 / 40079;
    // event time
    setField(
      Allen::LumiCounterOffsets::t0LowOffset,
      Allen::LumiCounterOffsets::t0LowSize,
      lumi_summary,
      static_cast<unsigned>(t0 & 0xffffffff));
    setField(
      Allen::LumiCounterOffsets::t0HighOffset,
      Allen::LumiCounterOffsets::t0HighSize,
      lumi_summary,
      static_cast<unsigned>(t0 >> 32));

    // gps time offset
    setField(
      Allen::LumiCounterOffsets::bcidLowOffset,
      Allen::LumiCounterOffsets::bcidLowSize,
      lumi_summary,
      static_cast<unsigned>(new_bcid & 0xffffffff));
    setField(
      Allen::LumiCounterOffsets::bcidHighOffset,
      Allen::LumiCounterOffsets::bcidHighSize,
      lumi_summary,
      static_cast<unsigned>(new_bcid >> 32));

    // bunch crossing type
    setField(
      Allen::LumiCounterOffsets::bxTypeOffset,
      Allen::LumiCounterOffsets::bxTypeSize,
      lumi_summary,
      static_cast<unsigned>(odin.bunchCrossingType()));

    /// gec counter
    for (unsigned i = 0; i < number_of_events_passed_gec; ++i) {
      if (parameters.dev_event_list[i] == event_number) {
        setField(Allen::LumiCounterOffsets::GecOffset, Allen::LumiCounterOffsets::GecSize, lumi_summary, true);
        break;
      }
    }

    /// Velo Counters
    // number of Velo tracks
    setField(
      Allen::LumiCounterOffsets::VeloTracksOffset,
      Allen::LumiCounterOffsets::VeloTracksSize,
      lumi_summary,
      parameters.dev_offsets_all_velo_tracks[event_number + 1] - parameters.dev_offsets_all_velo_tracks[event_number]);

    // number of Velo verteces
    setField(
      Allen::LumiCounterOffsets::VeloVerticesOffset,
      Allen::LumiCounterOffsets::VeloVerticesSize,
      lumi_summary,
      parameters.dev_number_of_pvs[event_number]);

    /// SciFi Counters
    setField(
      Allen::LumiCounterOffsets::SciFiClustersOffset,
      Allen::LumiCounterOffsets::SciFiClustersSize,
      lumi_summary,
      parameters.dev_scifi_hit_offsets[(event_number + 1) * SciFi::Constants::n_mat_groups_and_mats] -
        parameters.dev_scifi_hit_offsets[event_number * SciFi::Constants::n_mat_groups_and_mats]);

    /// muon Hits in different location
    const auto muon_hits_offsets = parameters.dev_storage_station_region_quarter_offsets +
                                   event_number * Muon::Constants::n_layouts * Muon::Constants::n_stations *
                                     Muon::Constants::n_regions * Muon::Constants::n_quarters;
    setField(
      Allen::LumiCounterOffsets::M2R2Offset,
      Allen::LumiCounterOffsets::M2R2Size,
      lumi_summary,
      muon_hits_offsets[Allen::LumiCounterOffsets::M2R3] - muon_hits_offsets[Allen::LumiCounterOffsets::M2R2]);

    setField(
      Allen::LumiCounterOffsets::M2R3Offset,
      Allen::LumiCounterOffsets::M2R3Size,
      lumi_summary,
      muon_hits_offsets[Allen::LumiCounterOffsets::M2R4] - muon_hits_offsets[Allen::LumiCounterOffsets::M2R3]);

    setField(
      Allen::LumiCounterOffsets::M3R2Offset,
      Allen::LumiCounterOffsets::M3R2Size,
      lumi_summary,
      muon_hits_offsets[Allen::LumiCounterOffsets::M3R3] - muon_hits_offsets[Allen::LumiCounterOffsets::M3R2]);

    setField(
      Allen::LumiCounterOffsets::M3R3Offset,
      Allen::LumiCounterOffsets::M3R3Size,
      lumi_summary,
      muon_hits_offsets[Allen::LumiCounterOffsets::M3R4] - muon_hits_offsets[Allen::LumiCounterOffsets::M3R3]);
  }
}
