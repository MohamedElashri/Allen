/*****************************************************************************\
* (c) Copyright 2018-2020 CERN for the benefit of the LHCb Collaboration      *
*                                                                             *
* This software is distributed under the terms of the Apache License          *
* version 2 (Apache-2.0), copied verbatim in the file "LICENSE".              *
*                                                                             *
* In applying this licence, CERN does not waive the privileges and immunities *
* granted to it by virtue of its status as an Intergovernmental Organization  *
* or submit itself to any jurisdiction.                                       *
\*****************************************************************************/
#include <UTDecodingPredecodeHits.cuh>
#include <PrefixSum.cuh>
#include <UTUniqueID.cuh>

INSTANTIATE_ALGORITHM(ut_decoding_predecode_hits::ut_decoding_predecode_hits_t)

void ut_decoding_predecode_hits::ut_decoding_predecode_hits_t::set_arguments_size(
  ArgumentReferences<Parameters> arguments,
  const RuntimeOptions&,
  const Constants&) const
{
  const auto num_hits = first<host_total_number_of_ut_hits_t>(arguments);
  const auto num_events = first<host_number_of_events_t>(arguments);
  using UT::Constants::n_groups;

  set_size<dev_ut_hits_strip_info_t>(arguments, num_hits);
  set_size<dev_ut_predecoded_hits_t>(arguments, num_hits);
  set_size<dev_ut_lane_mask_t>(arguments, size<dev_ut_lanes_hit_offsets_t>(arguments));
  set_size<dev_ut_predecoded_event_offsets_t>(arguments, num_events + 1);
}

void ut_decoding_predecode_hits::ut_decoding_predecode_hits_t::operator()(
  const ArgumentReferences<Parameters>& arguments,
  const RuntimeOptions& runtime_options,
  const Constants& constants,
  const Allen::Context& context) const
{
  const auto num_hits = first<host_total_number_of_ut_hits_t>(arguments);

  // If there's not any UT hit, we should skip it
  if (num_hits == 0) {
    Allen::memset_async<dev_ut_predecoded_event_offsets_t>(arguments, 0, context);
    return;
  }

  // Bank dependent info
  auto const bank_version = first<host_raw_bank_version_t>(arguments);

  // Reset
  Allen::memset_async<dev_ut_predecoded_event_offsets_t>(arguments, 0, context);

  //
  // Prepare the predecoding
  //
  {
    auto global_func = bank_version == 4 ? global_function(ut_decoding_prepare_predecode<4>) :
                                           global_function(ut_decoding_prepare_predecode<3>);
    global_func(dim3(size<dev_event_list_t>(arguments)), m_block_dim, context)(arguments);
  }
  PrefixSum::prefix_sum<dev_ut_lane_mask_t>(*this, arguments, context);

  // Predecode hits
  auto global_func = bank_version == 4 ?
                       (runtime_options.mep_layout ? global_function(ut_decoding_predecode<4, true>) :
                                                     global_function(ut_decoding_predecode<4, false>)) :
                       (runtime_options.mep_layout ? global_function(ut_decoding_predecode<3, true>) :
                                                     global_function(ut_decoding_predecode<3, false>));

  global_func(dim3(size<dev_event_list_t>(arguments)), m_block_dim, context)(
    arguments, std::get<0>(runtime_options.event_interval), constants.dev_ut_boards.data());

  // print<dev_ut_predecoded_sector_group_offsets_t>(arguments);
  PrefixSum::prefix_sum<dev_ut_predecoded_event_offsets_t>(*this, arguments, context);
}

template<unsigned version>
__global__ void ut_decoding_predecode_hits::ut_decoding_prepare_predecode(Parameters parameters)
{
  // Basics
  const auto event_number = parameters.dev_event_list[blockIdx.x];

  // Alias
  constexpr unsigned n_lanes = (version == 4) ? UT::Decoding::v5::n_lanes : 1;

  // Get number of hits
  const auto event_bank_offset = parameters.dev_ut_banks_offsets[event_number];
  const auto event_num_banks = parameters.dev_ut_banks_offsets[event_number + 1] - event_bank_offset;
  const auto event_num_lanes = event_num_banks * n_lanes;
  const auto hit_offsets = parameters.dev_ut_lanes_hit_offsets + event_bank_offset * n_lanes;
  const auto lane_offset = event_bank_offset * n_lanes;

  for (unsigned i = threadIdx.x; i < event_num_lanes; i += blockDim.x) {
    const auto hit_start = hit_offsets[i];
    const auto hit_end = hit_offsets[i + 1];
    for (unsigned hit = hit_start; hit < hit_end; hit++) {
      parameters.dev_ut_predecoded_hits[hit] = i;
    }
    parameters.dev_ut_lane_mask[lane_offset + i] = hit_end > hit_start;
  }
}

template<unsigned version, bool mep>
__global__ void ut_decoding_predecode_hits::ut_decoding_predecode(
  Parameters parameters,
  const unsigned event_start,
  const char* ut_boards)
{
  // Basics
  const auto event_number = parameters.dev_event_list[blockIdx.x];

  // Alias
  constexpr unsigned n_lanes = (version == 4) ? UT::Decoding::v5::n_lanes : 1;

  // Get number of hits
  const auto event_bank_offset = parameters.dev_ut_banks_offsets[event_number];
  const auto event_num_banks = parameters.dev_ut_banks_offsets[event_number + 1] - event_bank_offset;
  const auto event_lane_offset = event_bank_offset * n_lanes;
  const auto event_hit_offset = parameters.dev_ut_lanes_hit_offsets[event_lane_offset];
  const auto event_num_hits =
    parameters.dev_ut_lanes_hit_offsets[(event_bank_offset + event_num_banks) * n_lanes] - event_hit_offset;

  // Output
  auto sector_group_counter = parameters.dev_ut_predecoded_event_offsets + event_number;

  // Useful indices
  const auto hit_offsets = parameters.dev_ut_lanes_hit_offsets + event_lane_offset;

  // Fetch raw data
  const UTRawEvent<mep> raw_event {parameters.dev_ut_raw_input,
                                   parameters.dev_ut_raw_input_offsets,
                                   parameters.dev_ut_raw_input_sizes,
                                   parameters.dev_ut_raw_input_types,
                                   event_number + event_start};

  // unsigned lane_idx = 0;
  for (unsigned hit_idx = threadIdx.x; hit_idx < event_num_hits; hit_idx += blockDim.x) {
    const auto lane_idx = parameters.dev_ut_predecoded_hits[event_hit_offset + hit_idx];

    // Get indices
    const auto bank = lane_idx / n_lanes;
    const auto lane = lane_idx % n_lanes;

    // Get offesets
    const auto hit_index_in_lane = (hit_idx + event_hit_offset) - hit_offsets[lane_idx];

    // Get sign (force the discontinuities cross lanes)
    const auto sign = parameters.dev_ut_lane_mask[event_lane_offset + lane_idx] % 2;

    // Get bank
    UTRawBank<version> raw_bank = raw_event.template raw_bank<version>(bank);

    // Start
    uint16_t word;
    uint16_t fullChanIndex;
    uint16_t stripID;
    uint16_t adc_count;
    if constexpr (version == 3) {
      const UTBoards boards(ut_boards);
      const uint32_t m_nStripsPerHybrid = boards.stripsPerHybrids[raw_bank.sourceID];

      // Extract values from raw_data
      word = raw_bank.data[hit_index_in_lane];
      const uint32_t channelID = (word & UT::Decoding::v4::chan_mask) >> UT::Decoding::v4::chan_offset;

      // Calculate the relative index of the corresponding board
      const uint32_t index = channelID / m_nStripsPerHybrid;
      stripID = channelID - (index * m_nStripsPerHybrid) + 1;
      fullChanIndex = raw_bank.sourceID * UT::Decoding::ut_number_of_sectors_per_board + index;

      // Fill adc count
      adc_count = 1u;
    }
    else {
      const uint16_t hit_index_in_raw_bank = 16 * (hit_index_in_lane / 2) + 2 * (5 - lane) + hit_index_in_lane % 2;
      word = raw_bank.data[hit_index_in_raw_bank];
      fullChanIndex = raw_bank.sourceID * UT::Decoding::ut_number_of_sectors_per_board + lane;
      stripID = (word & UT::Decoding::v5::strip_mask) >> UT::Decoding::v5::strip_offset;
      adc_count = (word & UT::Decoding::v5::adc_mask) >> UT::Decoding::v5::adc_offset;
    }

    // Save results
    parameters.dev_ut_predecoded_hits[event_hit_offset + hit_idx] =
      UTDecoding::PredecodeHitInfo(word, fullChanIndex).data;
    parameters.dev_ut_hits_strip_info[event_hit_offset + hit_idx] =
      UTDecoding::UTStripInfo(sign, stripID, adc_count).data;

    atomicAdd(sector_group_counter, 1u);
  }
}
