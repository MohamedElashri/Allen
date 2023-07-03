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

#include "SelectionsEventModel.cuh"
#include "Event/ODIN.h"

INSTANTIATE_ALGORITHM(make_lumi_summary::make_lumi_summary_t)

void make_lumi_summary::make_lumi_summary_t::set_arguments_size(
  ArgumentReferences<Parameters> arguments,
  const RuntimeOptions&,
  const Constants&) const
{
  set_size<host_lumi_summary_offsets_t>(arguments, size<dev_lumi_summary_offsets_t>(arguments));
  set_size<host_lumi_summaries_t>(arguments, first<host_lumi_summaries_size_t>(arguments));
  set_size<dev_lumi_summaries_t>(arguments, first<host_lumi_summaries_size_t>(arguments));
}

void make_lumi_summary::make_lumi_summary_t::init()
{
  std::map<std::string, std::pair<unsigned, unsigned>> schema = property<lumi_counter_schema_t>();

  unsigned c_idx(0u);
  for (auto counter_name : Lumi::Constants::basic_counter_names) {
    if (schema.find(counter_name) == schema.end()) {
      std::cout << "LumiSummary schema does not use " << counter_name << std::endl;
    }
    else {
      m_offsets_and_sizes[2 * c_idx] = schema[counter_name].first;
      m_offsets_and_sizes[2 * c_idx + 1] = schema[counter_name].second;
    }
    ++c_idx;
  }
}

void make_lumi_summary::make_lumi_summary_t::operator()(
  const ArgumentReferences<Parameters>& arguments,
  const RuntimeOptions&,
  const Constants&,
  const Allen::Context& context) const
{
  Allen::memset_async<dev_lumi_summaries_t>(arguments, 0xffffffff, context);

  // info aggregating
  std::array<const Lumi::LumiInfo*, Lumi::Constants::n_sub_infos> lumiInfos = {data<dev_velo_info_t>(arguments),
                                                                               data<dev_pv_info_t>(arguments),
                                                                               data<dev_scifi_info_t>(arguments),
                                                                               data<dev_muon_info_t>(arguments),
                                                                               data<dev_calo_info_t>(arguments),
                                                                               data<dev_plume_info_t>(arguments)};
  // set the size to 0 for empty dummy input
  // otherwise set it to the numbers of lumi counters
  std::array<unsigned, Lumi::Constants::n_sub_infos> infoSize = {
    std::min(Lumi::Constants::n_velo_counters, static_cast<unsigned>(size<dev_velo_info_t>(arguments))),
    std::min(Lumi::Constants::n_pv_counters, static_cast<unsigned>(size<dev_pv_info_t>(arguments))),
    std::min(Lumi::Constants::n_scifi_counters, static_cast<unsigned>(size<dev_scifi_info_t>(arguments))),
    std::min(Lumi::Constants::n_muon_counters, static_cast<unsigned>(size<dev_muon_info_t>(arguments))),
    std::min(Lumi::Constants::n_calo_counters, static_cast<unsigned>(size<dev_calo_info_t>(arguments))),
    std::min(Lumi::Constants::n_plume_counters, static_cast<unsigned>(size<dev_plume_info_t>(arguments)))};
  unsigned size_of_aggregate = Lumi::Constants::n_sub_infos;
  for (unsigned i = 1u; i <= size_of_aggregate; ++i) {
    if (infoSize[i - 1] == 0u) {
      // move the items after the empty LumiInfo forward
      // to replace the empty object
      for (unsigned j = i; j < size_of_aggregate; ++j) {
        lumiInfos[j - 1] = lumiInfos[j];
        infoSize[j - 1] = infoSize[j];
      }
      i--;
      size_of_aggregate--;
    }
  }

  global_function(make_lumi_summary)(dim3(4u), property<block_dim_t>(), context)(
    arguments,
    first<host_number_of_events_t>(arguments),
    size<dev_event_list_t>(arguments),
    m_offsets_and_sizes,
    lumiInfos,
    infoSize,
    size_of_aggregate);

  Allen::copy_async<host_lumi_summaries_t, dev_lumi_summaries_t>(arguments, context);
  Allen::copy_async<host_lumi_summary_offsets_t, dev_lumi_summary_offsets_t>(arguments, context);
}

__device__ void
make_lumi_summary::setField(unsigned offset, unsigned size, unsigned* target, unsigned value, unsigned summary_length)
{
  // Check value fits within size bits
  if (size < (8 * sizeof(unsigned)) && value >= (1u << size)) {
    return;
  }

  // Separate offset into a word part and bit part
  unsigned word = offset / (8 * sizeof(unsigned));
  unsigned bitoffset = offset % (8 * sizeof(unsigned));

  // Check offset within allowed size
  if (word >= summary_length) {
    return;
  }
  // Check size and offset line up with word boundaries
  if (bitoffset + size > (8 * sizeof(unsigned))) {
    return;
  }

  // Apply the value to the matching bits
  unsigned mask = ((1l << size) - 1) << bitoffset;
  target[word] = (target[word] & ~mask) | ((value << bitoffset) & mask);
}

__global__ void make_lumi_summary::make_lumi_summary(
  make_lumi_summary::Parameters parameters,
  const unsigned number_of_events,
  const unsigned number_of_events_passed_gec,
  const offsets_and_sizes_t offsets_and_sizes,
  std::array<const Lumi::LumiInfo*, Lumi::Constants::n_sub_infos> lumiInfos,
  std::array<unsigned, Lumi::Constants::n_sub_infos> infoSize,
  const unsigned size_of_aggregate)
{
  for (unsigned event_number = blockIdx.x * blockDim.x + threadIdx.x; event_number < number_of_events;
       event_number += blockDim.x * gridDim.x) {
    unsigned offset = parameters.dev_lumi_summary_offsets[event_number];
    unsigned evt_index = parameters.dev_lumi_event_indices[event_number];

    // skip non-lumi event
    unsigned sum_length = parameters.dev_lumi_summary_offsets[event_number + 1] - offset;
    if (sum_length == 0u) continue;

    auto* lumi_summary = parameters.dev_lumi_summaries + offset;
    if (sum_length > parameters.lumi_sum_length) {
      lumi_summary[0] = parameters.key_full;
    }
    else {
      lumi_summary[0] = parameters.key;
    }

    /// ODIN information
    const LHCb::ODIN odin {parameters.dev_odin_data[event_number]};
    uint64_t new_bcid = static_cast<uint32_t>(odin.orbitNumber()) * 3564 + static_cast<uint16_t>(odin.bunchId());
    uint64_t t0 = static_cast<uint64_t>(odin.gpsTime()) - new_bcid * 1000 / 40078;
    // event time
    setField(
      offsets_and_sizes[0], offsets_and_sizes[1], lumi_summary, static_cast<unsigned>(t0 & 0xffffffff), sum_length);
    setField(offsets_and_sizes[2], offsets_and_sizes[3], lumi_summary, static_cast<unsigned>(t0 >> 32), sum_length);

    // gps time offset
    setField(
      offsets_and_sizes[4],
      offsets_and_sizes[5],
      lumi_summary,
      static_cast<unsigned>(new_bcid & 0xffffffff),
      sum_length);
    setField(
      offsets_and_sizes[6], offsets_and_sizes[7], lumi_summary, static_cast<unsigned>(new_bcid >> 32), sum_length);

    // bunch crossing type
    setField(
      offsets_and_sizes[8],
      offsets_and_sizes[9],
      lumi_summary,
      static_cast<unsigned>(odin.bunchCrossingType()),
      sum_length);

    /// gec counter
    bool passedGEC = false;
    for (unsigned i = 0; i < number_of_events_passed_gec; ++i) {
      if (parameters.dev_event_list[i] == event_number) {
        passedGEC = true;
        break;
      }
    }
    setField(offsets_and_sizes[10], offsets_and_sizes[11], lumi_summary, passedGEC, sum_length);

    /// write lumi infos to the summary
    for (unsigned i = 0; i < size_of_aggregate; ++i) {
      if (infoSize[i] == 0 || lumiInfos[i] == nullptr) continue;
      unsigned spanOffset = evt_index * infoSize[i];
      for (unsigned j = spanOffset; j < parameters.dev_lumi_event_indices[event_number + 1] * infoSize[i]; ++j) {
        setField(lumiInfos[i][j].offset, lumiInfos[i][j].size, lumi_summary, lumiInfos[i][j].value, sum_length);
      }
    }
  }
}
