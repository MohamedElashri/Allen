/*****************************************************************************\
* (c) Copyright 2018-2020 CERN for the benefit of the LHCb Collaboration      *
\*****************************************************************************/
#include <MEPTools.h>
#include <UTDecodeRawBanksInOrder.cuh>

void ut_decode_raw_banks_in_order::ut_decode_raw_banks_in_order_t::set_arguments_size(
  ArgumentReferences<Parameters> arguments,
  const RuntimeOptions&,
  const Constants&,
  const HostBuffers&) const
{
  set_size<dev_ut_hits_t>(arguments, first<host_accumulated_number_of_ut_hits_t>(arguments) * UT::Hits::element_size);
}

void ut_decode_raw_banks_in_order::ut_decode_raw_banks_in_order_t::operator()(
  const ArgumentReferences<Parameters>& arguments,
  const RuntimeOptions& runtime_options,
  const Constants& constants,
  HostBuffers&,
  cudaStream_t& cuda_stream,
  cudaEvent_t&) const
{
  if (runtime_options.mep_layout) {
    global_function(ut_decode_raw_banks_in_order_mep)(
      dim3(first<host_number_of_selected_events_t>(arguments), UT::Constants::n_layers),
      property<block_dim_t>(),
      cuda_stream)(
      arguments,
      constants.dev_ut_boards.data(),
      constants.dev_ut_geometry.data(),
      constants.dev_ut_region_offsets.data(),
      constants.dev_unique_x_sector_layer_offsets.data());
  }
  else {
    global_function(ut_decode_raw_banks_in_order)(
      dim3(first<host_number_of_selected_events_t>(arguments), UT::Constants::n_layers),
      property<block_dim_t>(),
      cuda_stream)(
      arguments,
      constants.dev_ut_boards.data(),
      constants.dev_ut_geometry.data(),
      constants.dev_ut_region_offsets.data(),
      constants.dev_unique_x_sector_layer_offsets.data());
  }
}

__device__ void decode_raw_bank(
  unsigned const* dev_ut_region_offsets,
  UTGeometry const& geometry,
  UTBoards const& boards,
  UTRawBank const& raw_bank,
  unsigned const hit_index,
  unsigned const raw_bank_hit_index,
  UT::Hits& ut_hits)
{
  const unsigned hit_index_inside_raw_bank = raw_bank_hit_index & 0xFFFFFF;

  const uint16_t value = raw_bank.data[hit_index_inside_raw_bank];
  const uint32_t nStripsPerHybrid = boards.stripsPerHybrids[raw_bank.sourceID];

  // Extract values from raw_data
  const uint32_t fracStrip = (value & UT::Decoding::frac_mask) >> UT::Decoding::frac_offset;
  const uint32_t channelID = (value & UT::Decoding::chan_mask) >> UT::Decoding::chan_offset;
  // const uint32_t threshold = (value & UT::Decoding::thre_mask) >> UT::Decoding::thre_offset;

  // Calculate the relative index of the corresponding board
  const uint32_t index = channelID / nStripsPerHybrid;
  const uint32_t strip = channelID - (index * nStripsPerHybrid) + 1;

  const uint32_t fullChanIndex = raw_bank.sourceID * UT::Decoding::ut_number_of_sectors_per_board + index;
  const uint32_t station = boards.stations[fullChanIndex] - 1;
  const uint32_t layer = boards.layers[fullChanIndex] - 1;
  const uint32_t detRegion = boards.detRegions[fullChanIndex] - 1;
  const uint32_t sector = boards.sectors[fullChanIndex] - 1;
  const uint32_t chanID = boards.chanIDs[fullChanIndex];

  // Calculate the index to get the geometry of the board
  const uint32_t idx = station * UT::Decoding::ut_number_of_sectors_per_board + layer * 3 + detRegion;
  const uint32_t idx_offset = dev_ut_region_offsets[idx] + sector;

  const uint32_t firstStrip = geometry.firstStrip[idx_offset];
  const float pitch = geometry.pitch[idx_offset];
  const float dy = geometry.dy[idx_offset];
  const float dp0diX = geometry.dp0diX[idx_offset];
  const float dp0diY = geometry.dp0diY[idx_offset];
  const float dp0diZ = geometry.dp0diZ[idx_offset];
  const float p0X = geometry.p0X[idx_offset];
  const float p0Y = geometry.p0Y[idx_offset];
  const float p0Z = geometry.p0Z[idx_offset];

  const float numstrips = 0.25f * fracStrip + strip - firstStrip;

  // Calculate values of the hit
  const float yBegin = p0Y + numstrips * dp0diY;
  const float yEnd = dy + yBegin;
  const float zAtYEq0 = p0Z + numstrips * dp0diZ;
  const float xAtYEq0 = p0X + numstrips * dp0diX;
  const float weight = 12.f / (pitch * pitch);

  // const uint32_t highThreshold = threshold;
  const uint32_t channelStripID = chanID + strip;
  const uint32_t LHCbID = (((uint32_t) 0xB) << 28) | channelStripID;
  // const uint32_t planeCode = 2 * station + (layer & 1);

  ut_hits.yBegin(hit_index) = yBegin;
  ut_hits.yEnd(hit_index) = yEnd;
  ut_hits.zAtYEq0(hit_index) = zAtYEq0;
  ut_hits.xAtYEq0(hit_index) = xAtYEq0;
  ut_hits.weight(hit_index) = weight;
  ut_hits.id(hit_index) = LHCbID;
}

__global__ void ut_decode_raw_banks_in_order::ut_decode_raw_banks_in_order(
  ut_decode_raw_banks_in_order::Parameters parameters,
  const char* ut_boards,
  const char* ut_geometry,
  const unsigned* dev_ut_region_offsets,
  const unsigned* dev_unique_x_sector_layer_offsets)
{
  const uint32_t number_of_events = gridDim.x;
  const uint32_t event_number = blockIdx.x;
  const unsigned selected_event_number = parameters.dev_event_list[event_number];

  const unsigned layer_number = blockIdx.y;
  const uint32_t event_offset = parameters.dev_ut_raw_input_offsets[selected_event_number];

  const unsigned number_of_unique_x_sectors = dev_unique_x_sector_layer_offsets[UT::Constants::n_layers];

  const UT::HitOffsets ut_hit_offsets {
    parameters.dev_ut_hit_offsets, event_number, number_of_unique_x_sectors, dev_unique_x_sector_layer_offsets};
  UT::Hits ut_hits {
    parameters.dev_ut_hits, parameters.dev_ut_hit_offsets[number_of_events * number_of_unique_x_sectors]};

  UT::ConstPreDecodedHits ut_pre_decoded_hits {
    parameters.dev_ut_pre_decoded_hits, parameters.dev_ut_hit_offsets[number_of_events * number_of_unique_x_sectors]};

  const UTRawEvent raw_event(parameters.dev_ut_raw_input + event_offset);
  const UTBoards boards(ut_boards);
  const UTGeometry geometry(ut_geometry);

  const unsigned layer_offset = ut_hit_offsets.layer_offset(layer_number);
  const unsigned layer_number_of_hits = ut_hit_offsets.layer_number_of_hits(layer_number);

  for (unsigned i = threadIdx.x; i < layer_number_of_hits; i += blockDim.x) {
    const unsigned hit_index = layer_offset + i;
    const unsigned raw_bank_hit_index = ut_pre_decoded_hits.index(parameters.dev_ut_hit_permutations[hit_index]);
    const unsigned raw_bank_index = raw_bank_hit_index >> 24;

    const UTRawBank raw_bank = raw_event.getUTRawBank(raw_bank_index);

    decode_raw_bank(dev_ut_region_offsets, geometry, boards, raw_bank, hit_index, raw_bank_hit_index, ut_hits);
  }
}

__global__ void ut_decode_raw_banks_in_order::ut_decode_raw_banks_in_order_mep(
  ut_decode_raw_banks_in_order::Parameters parameters,
  const char* ut_boards,
  const char* ut_geometry,
  const unsigned* dev_ut_region_offsets,
  const unsigned* dev_unique_x_sector_layer_offsets)
{
  const uint32_t number_of_events = gridDim.x;
  const uint32_t event_number = blockIdx.x;
  const unsigned selected_event_number = parameters.dev_event_list[event_number];

  const unsigned layer_number = blockIdx.y;

  const unsigned number_of_unique_x_sectors = dev_unique_x_sector_layer_offsets[UT::Constants::n_layers];

  const UT::HitOffsets ut_hit_offsets {
    parameters.dev_ut_hit_offsets, event_number, number_of_unique_x_sectors, dev_unique_x_sector_layer_offsets};
  UT::Hits ut_hits {
    parameters.dev_ut_hits, parameters.dev_ut_hit_offsets[number_of_events * number_of_unique_x_sectors]};

  UT::ConstPreDecodedHits ut_pre_decoded_hits {
    parameters.dev_ut_pre_decoded_hits, parameters.dev_ut_hit_offsets[number_of_events * number_of_unique_x_sectors]};

  const UTBoards boards(ut_boards);
  const UTGeometry geometry(ut_geometry);

  const unsigned layer_offset = ut_hit_offsets.layer_offset(layer_number);
  const unsigned layer_number_of_hits = ut_hit_offsets.layer_number_of_hits(layer_number);

  for (unsigned i = threadIdx.x; i < layer_number_of_hits; i += blockDim.x) {

    const unsigned hit_index = layer_offset + i;
    const unsigned raw_bank_hit_index = ut_pre_decoded_hits.index(parameters.dev_ut_hit_permutations[hit_index]);
    const unsigned raw_bank_index = raw_bank_hit_index >> 24;

    // Create UT raw bank from MEP layout
    const auto raw_bank = MEP::raw_bank<UTRawBank>(
      parameters.dev_ut_raw_input, parameters.dev_ut_raw_input_offsets, selected_event_number, raw_bank_index);

    decode_raw_bank(dev_ut_region_offsets, geometry, boards, raw_bank, hit_index, raw_bank_hit_index, ut_hits);
  }
}
