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
#include <MEPTools.h>
#include <UTCalculateNumberOfHits.cuh>
#include <UTRaw.cuh>
#include <WarpIntrinsicsTools.cuh>
#include <PrefixSum.cuh>

INSTANTIATE_ALGORITHM(ut_calculate_number_of_hits::ut_calculate_number_of_hits_t)

void ut_calculate_number_of_hits::ut_calculate_number_of_hits_t::set_arguments_size(
  ArgumentReferences<Parameters> arguments,
  const RuntimeOptions&,
  const Constants&) const
{
  set_size<dev_ut_hit_offsets_t>(arguments, first<host_number_of_events_t>(arguments) * UT::Constants::n_groups + 1);
  set_size<dev_ut_nonempty_channels_t>(
    arguments, first<host_number_of_events_t>(arguments) * UT::Decoding::number_of_channels);
  set_size<dev_ut_number_of_nonempty_channels_t>(arguments, first<host_number_of_events_t>(arguments));
  set_size<host_total_sum_holder_t>(arguments, 1);
}

void ut_calculate_number_of_hits::ut_calculate_number_of_hits_t::operator()(
  const ArgumentReferences<Parameters>& arguments,
  const RuntimeOptions& runtime_options,
  const Constants& constants,
  const Allen::Context& context) const
{
  Allen::memset_async<dev_ut_hit_offsets_t>(arguments, 0, context);

  auto const bank_version = first<host_raw_bank_version_t>(arguments);
  if (bank_version < 0) { // no UT banks present in data
    Allen::memset_async<host_total_sum_holder_t>(arguments, 0, context);
    return;
  }

  auto fun = bank_version == 4 ? (runtime_options.mep_layout ? global_function(ut_calculate_number_of_hits<4, true>) :
                                                               global_function(ut_calculate_number_of_hits<4, false>)) :
                                 (runtime_options.mep_layout ? global_function(ut_calculate_number_of_hits<3, true>) :
                                                               global_function(ut_calculate_number_of_hits<3, false>));

  fun(dim3(size<dev_event_list_t>(arguments)), m_block_dim, context)(
    arguments,
    std::get<0>(runtime_options.event_interval),
    constants.dev_ut_boards.data(),
    constants.dev_ut_sector_to_group_map.data(),
    constants.dev_ut_board_geometry_map.data());

  PrefixSum::prefix_sum<dev_ut_hit_offsets_t, host_total_sum_holder_t>(*this, arguments, context);

  if (m_verbosity >= logger::debug) {
    print<dev_ut_hit_offsets_t>(arguments);
    print<dev_ut_nonempty_channels_t>(arguments);
    print<dev_ut_number_of_nonempty_channels_t>(arguments);
    print<host_total_sum_holder_t>(arguments);
  }
}

// Decode large channels first and let the tail end be channels of size 1
__device__ inline uint8_t ut_decoding_size_to_bin(const uint32_t number_of_hits)
{
  // We only need 16 bins
  static_assert(UT::Decoding::number_of_channel_bins == 16u);

  // 16 hits or more: bin 0
  // everything else: bin = 16 - nhits
  // nhits is always >= 1, so max(bin) == 15
  const auto bin = (number_of_hits >= UT::Decoding::number_of_channel_bins) ?
                     0u :
                     UT::Decoding::number_of_channel_bins - number_of_hits;
  return static_cast<uint8_t>(bin);
}

// We are only doing prefix sum over 16 elements, just do it within the warp
__device__ inline void ut_decoding_prefix_sum_and_reset_count(unsigned* shared_count, unsigned* shared_offset)
{
// Either use warp prefix-sum (CUDA), or shared
// Not sure what to do for HIP
#ifndef TARGET_DEVICE_CPU

  __syncthreads();

  // Do a prefix sum over 8 elements
  const unsigned first_n_mask = __ballot_sync(0xFFFFFFFF, threadIdx.x < UT::Decoding::number_of_channel_bins);
  if (threadIdx.x < UT::Decoding::number_of_channel_bins) {
    unsigned offset = shared_count[threadIdx.x];
    for (unsigned delta = 1; delta < UT::Decoding::number_of_channel_bins; delta *= 2) {
      const auto temp = __shfl_up_sync(first_n_mask, offset, delta);
      if (threadIdx.x >= delta) offset += temp;
    }
    shared_offset[threadIdx.x + 1] = offset;
  }
  if (threadIdx.x == 0) shared_offset[0] = 0;
  // Reset the counters
  if (threadIdx.x < UT::Decoding::number_of_channel_bins) shared_count[threadIdx.x] = 0;

  __syncthreads();

#else

  // CPU implementation, iterate prefix sum sequentially
  unsigned offset = 0;
  shared_offset[0] = 0;
  for (unsigned i = 0; i < UT::Decoding::number_of_channel_bins; i++) {
    offset += shared_count[i];
    shared_offset[i + 1] = offset;
  }
  // Reset the counters
  for (unsigned i = 0; i < UT::Decoding::number_of_channel_bins; i++) {
    shared_count[i] = 0;
  }

#endif
}

/**
 * @brief Given a UT RawBank, this function calculates the number of hits in a sector_group
  ("virtual" structure for optimized processing; a group of sectors where the start X is of a certain value).
 */
template<int decoding_version>
__device__ void calculate_number_of_hits(
  unsigned const*,
  UTBoards const&,
  const uint16_t*,
  UTRawBank<decoding_version> const&,
  const unsigned,
  uint32_t*,
  uint8_t*,
  unsigned*)
{}

template<>
__device__ void calculate_number_of_hits<3>(
  unsigned const* dev_ut_sector_to_group_map,
  UTBoards const& boards,
  const uint16_t* dev_ut_board_geometry_map,
  UTRawBank<3> const& raw_bank,
  const unsigned channel_index,
  uint32_t* hit_offsets,
  uint8_t* shared_bin_number,
  unsigned* shared_bin_counter)
{
  const uint32_t m_nStripsPerHybrid = boards.stripsPerHybrids[raw_bank.sourceID];

  for (unsigned i = 0; i < raw_bank.number_of_hits[0]; i++) {
    const uint32_t channelID = (raw_bank.data[i] & UT::Decoding::v4::chan_mask) >> UT::Decoding::v4::chan_offset;
    const uint32_t index = channelID / m_nStripsPerHybrid;
    const uint32_t fullChanIndex = raw_bank.sourceID * UT::Decoding::ut_number_of_sectors_per_board + index;
    if (fullChanIndex >= boards.number_of_channels) continue;

    const uint16_t sec = dev_ut_board_geometry_map[fullChanIndex];
    unsigned* hits_sector_group = hit_offsets + dev_ut_sector_to_group_map[sec];
    Allen::warp::atomic_increment(hits_sector_group);
  }

  const uint8_t bin = ut_decoding_size_to_bin(raw_bank.number_of_hits[0]);
  shared_bin_number[channel_index] = bin;
  Allen::warp::atomic_increment(shared_bin_counter + bin);
}

template<>
__device__ void calculate_number_of_hits<4>(
  unsigned const* dev_ut_sector_to_group_map,
  UTBoards const& boards,
  const uint16_t* dev_ut_board_geometry_map,
  UTRawBank<4> const& raw_bank,
  const unsigned channel_index,
  uint32_t* hit_offsets,
  uint8_t* shared_bin_number,
  unsigned* shared_bin_counter)
{
  const unsigned lane_index = channel_index % UT::Decoding::v5::n_lanes;
  const uint32_t fullChanIndex = raw_bank.sourceID * UT::Decoding::ut_number_of_sectors_per_board + lane_index;
  if (fullChanIndex >= boards.number_of_channels) return;
  const uint16_t sec = dev_ut_board_geometry_map[fullChanIndex];

  unsigned* hits_sector_group = hit_offsets + dev_ut_sector_to_group_map[sec];
  atomicAdd(hits_sector_group, raw_bank.number_of_hits[lane_index]);

  const uint8_t bin = ut_decoding_size_to_bin(raw_bank.number_of_hits[lane_index]);
  shared_bin_number[channel_index] = bin;
  Allen::warp::atomic_increment(shared_bin_counter + bin);
}

/**
 * @brief Calculates the number of hits to be decoded for the UT detector.
 */
template<int decoding_version, bool mep>
__global__ void ut_calculate_number_of_hits::ut_calculate_number_of_hits(
  ut_calculate_number_of_hits::Parameters parameters,
  const unsigned event_start,
  const char* ut_boards,
  const unsigned* dev_ut_sector_to_group_map,
  const uint16_t* dev_ut_board_geometry_map)
{
  const unsigned event_number = parameters.dev_event_list[blockIdx.x];

  uint32_t* hit_offsets = parameters.dev_ut_hit_offsets + event_number * UT::Constants::n_groups;
  uint16_t* nonempty_channels = parameters.dev_ut_nonempty_channels + event_number * UT::Decoding::number_of_channels;
  const UTBoards boards {ut_boards};
  const UTRawEvent<mep> raw_event {parameters.dev_ut_raw_input,
                                   parameters.dev_ut_raw_input_offsets,
                                   parameters.dev_ut_raw_input_sizes,
                                   parameters.dev_ut_raw_input_types,
                                   event_number + event_start};

  // First fill shared counters
  __shared__ uint8_t shared_bin_number[UT::Decoding::number_of_channels];
  __shared__ unsigned shared_bins_count[UT::Decoding::number_of_channel_bins];

  for (unsigned channel_index = threadIdx.x; channel_index < UT::Decoding::number_of_channels;
       channel_index += blockDim.x) {
    shared_bin_number[channel_index] = UT::Decoding::empty_channel;
  }

  for (unsigned i = threadIdx.x; i < UT::Decoding::number_of_channel_bins; i += blockDim.x) {
    shared_bins_count[i] = 0;
  }

  __syncthreads();

  const uint16_t total_number_of_channels = (decoding_version == 4) ?
                                              raw_event.number_of_raw_banks() * UT::Decoding::v5::n_lanes :
                                              raw_event.number_of_raw_banks();
  for (uint16_t channel_index = threadIdx.x; channel_index < total_number_of_channels; channel_index += blockDim.x) {

    const uint16_t raw_bank_index = (decoding_version == 4) ? channel_index / UT::Decoding::v5::n_lanes : channel_index;
    const uint16_t lane_index = (decoding_version == 4) ? channel_index % UT::Decoding::v5::n_lanes : 0;

    UTRawBank<decoding_version> bank = raw_event.template raw_bank<decoding_version>(raw_bank_index);
    if (bank.number_of_hits[lane_index] == 0 || !UT::Decoding::allowed_rawbank_type(bank.type)) continue;

    calculate_number_of_hits(
      dev_ut_sector_to_group_map,
      boards,
      dev_ut_board_geometry_map,
      bank,
      channel_index,
      hit_offsets,
      shared_bin_number,
      shared_bins_count);
  }

  __shared__ unsigned shared_bins_offset[UT::Decoding::number_of_channel_bins + 1];
  ut_decoding_prefix_sum_and_reset_count(shared_bins_count, shared_bins_offset);

  for (unsigned channel_index = threadIdx.x; channel_index < UT::Decoding::number_of_channels;
       channel_index += blockDim.x) {
    const uint8_t bin = shared_bin_number[channel_index];
    if (bin != UT::Decoding::empty_channel) {
      const unsigned bin_count = Allen::warp::atomic_increment(shared_bins_count + bin);
      assert(bin_count <= shared_bins_offset[bin + 1] - shared_bins_offset[bin]);
      nonempty_channels[shared_bins_offset[bin] + bin_count] = channel_index;
    }
  }

  if (threadIdx.x == 0)
    parameters.dev_ut_number_of_nonempty_channels[event_number] =
      shared_bins_offset[UT::Decoding::number_of_channel_bins];
}
