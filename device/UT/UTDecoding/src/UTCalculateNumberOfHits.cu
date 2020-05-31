/*****************************************************************************\
* (c) Copyright 2018-2020 CERN for the benefit of the LHCb Collaboration      *
\*****************************************************************************/
#include <MEPTools.h>
#include <UTCalculateNumberOfHits.cuh>

void ut_calculate_number_of_hits::ut_calculate_number_of_hits_t::set_arguments_size(
  ArgumentReferences<Parameters> arguments,
  const RuntimeOptions&,
  const Constants& constants,
  const HostBuffers&) const
{
  set_size<dev_ut_hit_sizes_t>(
    arguments,
    first<host_number_of_events_t>(arguments) * constants.host_unique_x_sector_layer_offsets[4]);
}

void ut_calculate_number_of_hits::ut_calculate_number_of_hits_t::operator()(
  const ArgumentReferences<Parameters>& arguments,
  const RuntimeOptions& runtime_options,
  const Constants& constants,
  HostBuffers&,
  cudaStream_t& stream,
  cudaEvent_t&) const
{
  initialize<dev_ut_hit_sizes_t>(arguments, 0, stream);

  if (runtime_options.mep_layout) {
    global_function(ut_calculate_number_of_hits_mep)(dim3(first<host_number_of_events_t>(arguments)), property<block_dim_t>(), stream)(
      arguments,
      constants.dev_ut_boards.data(),
      constants.dev_ut_region_offsets.data(),
      constants.dev_unique_x_sector_layer_offsets.data(),
      constants.dev_unique_x_sector_offsets.data());
  } else {
    global_function(ut_calculate_number_of_hits)(dim3(first<host_number_of_events_t>(arguments)), property<block_dim_t>(), stream)(
      arguments,
      constants.dev_ut_boards.data(),
      constants.dev_ut_region_offsets.data(),
      constants.dev_unique_x_sector_layer_offsets.data(),
      constants.dev_unique_x_sector_offsets.data());
  }
}

__device__ void calculate_number_of_hits(
  unsigned const* dev_ut_region_offsets,
  unsigned const* dev_unique_x_sector_offsets,
  uint32_t* hit_offsets,
  UTBoards const& boards,
  UTRawBank const& raw_bank)
{
  const uint32_t m_nStripsPerHybrid = boards.stripsPerHybrids[raw_bank.sourceID];

  for (unsigned i = threadIdx.y; i < raw_bank.number_of_hits; i += blockDim.y) {
    const uint32_t channelID = (raw_bank.data[i] & UT::Decoding::chan_mask) >> UT::Decoding::chan_offset;
    const uint32_t index = channelID / m_nStripsPerHybrid;
    const uint32_t fullChanIndex = raw_bank.sourceID * UT::Decoding::ut_number_of_sectors_per_board + index;
    const uint32_t station = boards.stations[fullChanIndex] - 1;
    const uint32_t layer = boards.layers[fullChanIndex] - 1;
    const uint32_t detRegion = boards.detRegions[fullChanIndex] - 1;
    const uint32_t sector = boards.sectors[fullChanIndex] - 1;

    // Calculate the index to get the geometry of the board
    const uint32_t idx = station * UT::Decoding::ut_number_of_sectors_per_board + layer * 3 + detRegion;
    const uint32_t idx_offset = dev_ut_region_offsets[idx] + sector;

    unsigned* hits_sector_group = hit_offsets + dev_unique_x_sector_offsets[idx_offset];
    atomicAdd(hits_sector_group, 1);
  }
}

/**
 * @brief Calculates the number of hits to be decoded for the UT detector.
 */
__global__ void ut_calculate_number_of_hits::ut_calculate_number_of_hits(
  ut_calculate_number_of_hits::Parameters parameters,
  const char* ut_boards,
  const unsigned* dev_ut_region_offsets,
  const unsigned* dev_unique_x_sector_layer_offsets,
  const unsigned* dev_unique_x_sector_offsets)
{
  const uint32_t event_number = blockIdx.x;
  const unsigned selected_event_number = parameters.dev_event_list[event_number];

  const uint32_t event_offset = parameters.dev_ut_raw_input_offsets[selected_event_number];
  const unsigned number_of_unique_x_sectors = dev_unique_x_sector_layer_offsets[4];
  uint32_t* hit_offsets = parameters.dev_ut_hit_sizes + event_number * number_of_unique_x_sectors;

  const UTRawEvent raw_event(parameters.dev_ut_raw_input + event_offset);
  const UTBoards boards(ut_boards);

  for (unsigned raw_bank_index = threadIdx.x; raw_bank_index < raw_event.number_of_raw_banks;
       raw_bank_index += blockDim.x) {
    const UTRawBank raw_bank = raw_event.getUTRawBank(raw_bank_index);
    calculate_number_of_hits(dev_ut_region_offsets, dev_unique_x_sector_offsets, hit_offsets, boards, raw_bank);
  }
}

/**
 * @brief Calculates the number of hits to be decoded for the UT detector.
 */
__global__ void ut_calculate_number_of_hits::ut_calculate_number_of_hits_mep(
  ut_calculate_number_of_hits::Parameters parameters,
  const char* ut_boards,
  const unsigned* dev_ut_region_offsets,
  const unsigned* dev_unique_x_sector_layer_offsets,
  const unsigned* dev_unique_x_sector_offsets)
{
  const uint32_t event_number = blockIdx.x;
  const unsigned selected_event_number = parameters.dev_event_list[event_number];

  const unsigned number_of_unique_x_sectors = dev_unique_x_sector_layer_offsets[4];
  uint32_t* hit_offsets = parameters.dev_ut_hit_sizes + event_number * number_of_unique_x_sectors;

  const UTBoards boards(ut_boards);
  auto const number_of_ut_raw_banks = parameters.dev_ut_raw_input_offsets[0];

  for (unsigned raw_bank_index = threadIdx.x; raw_bank_index < number_of_ut_raw_banks; raw_bank_index += blockDim.x) {

    // Construct UT raw bank from MEP layout
    const auto raw_bank = MEP::raw_bank<UTRawBank>(
      parameters.dev_ut_raw_input, parameters.dev_ut_raw_input_offsets, selected_event_number, raw_bank_index);

    calculate_number_of_hits(dev_ut_region_offsets, dev_unique_x_sector_offsets, hit_offsets, boards, raw_bank);
  }
}
