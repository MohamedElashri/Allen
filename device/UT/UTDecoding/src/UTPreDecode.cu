/*****************************************************************************\
* (c) Copyright 2018-2020 CERN for the benefit of the LHCb Collaboration      *
\*****************************************************************************/
#include <MEPTools.h>
#include <UTPreDecode.cuh>

void ut_pre_decode::ut_pre_decode_t::set_arguments_size(
  ArgumentReferences<Parameters> arguments,
  const RuntimeOptions&,
  const Constants& constants,
  const HostBuffers&) const
{
  set_size<dev_ut_pre_decoded_hits_t>(
    arguments, first<host_accumulated_number_of_ut_hits_t>(arguments) * UT::PreDecodedHits::element_size);
  set_size<dev_ut_hit_count_t>(
    arguments, first<host_number_of_events_t>(arguments) * constants.host_unique_x_sector_layer_offsets[4]);
}

void ut_pre_decode::ut_pre_decode_t::operator()(
  const ArgumentReferences<Parameters>& arguments,
  const RuntimeOptions& runtime_options,
  const Constants& constants,
  HostBuffers&,
  const Allen::Context& context) const
{
  initialize<dev_ut_hit_count_t>(arguments, 0, context);

  if (runtime_options.mep_layout) {
    global_function(ut_pre_decode_mep)(dim3(size<dev_event_list_t>(arguments)), property<block_dim_t>(), stream)(
      arguments,
      constants.dev_ut_boards.data(),
      constants.dev_ut_geometry.data(),
      constants.dev_ut_region_offsets.data(),
      constants.dev_unique_x_sector_layer_offsets.data(),
      constants.dev_unique_x_sector_offsets.data());
  }
  else {
    global_function(ut_pre_decode)(dim3(size<dev_event_list_t>(arguments)), property<block_dim_t>(), stream)(
      arguments,
      constants.dev_ut_boards.data(),
      constants.dev_ut_geometry.data(),
      constants.dev_ut_region_offsets.data(),
      constants.dev_unique_x_sector_layer_offsets.data(),
      constants.dev_unique_x_sector_offsets.data());
  }
}

__device__ void pre_decode_raw_bank(
  unsigned const* dev_ut_region_offsets,
  unsigned const* dev_unique_x_sector_offsets,
  uint32_t const* hit_offsets,
  UTGeometry const& geometry,
  UTBoards const& boards,
  UTRawBank const& raw_bank,
  unsigned const raw_bank_index,
  UT::PreDecodedHits& ut_pre_decoded_hits,
  uint32_t* hit_count)
{
  const uint32_t m_nStripsPerHybrid = boards.stripsPerHybrids[raw_bank.sourceID];

  for (unsigned i = threadIdx.y; i < raw_bank.number_of_hits; i += blockDim.y) {
    // Extract values from raw_data
    const uint16_t value = raw_bank.data[i];
    const uint32_t fracStrip = (value & UT::Decoding::frac_mask) >> UT::Decoding::frac_offset;
    const uint32_t channelID = (value & UT::Decoding::chan_mask) >> UT::Decoding::chan_offset;

    // Calculate the relative index of the corresponding board
    const uint32_t index = channelID / m_nStripsPerHybrid;
    const uint32_t strip = channelID - (index * m_nStripsPerHybrid) + 1;

    const uint32_t fullChanIndex = raw_bank.sourceID * UT::Decoding::ut_number_of_sectors_per_board + index;
    const uint32_t station = boards.stations[fullChanIndex] - 1;
    const uint32_t layer = boards.layers[fullChanIndex] - 1;
    const uint32_t detRegion = boards.detRegions[fullChanIndex] - 1;
    const uint32_t sector = boards.sectors[fullChanIndex] - 1;

    // Calculate the index to get the geometry of the board
    const uint32_t idx = station * UT::Decoding::ut_number_of_sectors_per_board + layer * 3 + detRegion;
    const uint32_t idx_offset = dev_ut_region_offsets[idx] + sector;

    const uint32_t firstStrip = geometry.firstStrip[idx_offset];
    const float dp0diX = geometry.dp0diX[idx_offset];
    const float dp0diY = geometry.dp0diY[idx_offset];
    const float p0Y = geometry.p0Y[idx_offset];
    const float numstrips = 0.25f * fracStrip + strip - firstStrip;

    // Make a composed value made out of:
    // (first 16 bits of yBegin) | (first 16 bits of xAtYEq0_local)
    //
    // Rationale:
    // Sorting in floats is done the same way as for ints,
    // the bigger the binary number, the bigger the float (it's a designed property
    // of the float format). Also, the format of a float is as follows:
    // * 1 bit: sign
    // * 8 bits: exponent
    // * 23 bits: mantissa
    // By using the first 16 bits of each, we get the sign, exponent and 7 bits
    // of the mantissa, for both Y and X, which is enough to account for the
    // cases where yBegin was repeated.
    const auto yBegin = __float2half(p0Y + numstrips * dp0diY);
    const auto xAtYEq0_local = __float2half(numstrips * dp0diX);
    const int16_t* yBegin_p = reinterpret_cast<const int16_t*>(&yBegin);
    const int16_t* xAtYEq0_local_p = reinterpret_cast<const int16_t*>(&xAtYEq0_local);

    // The second value needs to be changed its sign using the 2's complement logic (operator-),
    // if the signs of both values differ.
    const int16_t composed_0 = yBegin_p[0];
    int16_t composed_1 = xAtYEq0_local_p[0];
    const bool sign_0 = composed_0 & 0x8000;
    const bool sign_1 = composed_1 & 0x8000;
    if (sign_0 ^ sign_1) {
      composed_1 = -composed_1;
    }

    const int composed_value = ((composed_0 << 16) & 0xFFFF0000) | (composed_1 & 0x0000FFFF);
    const float* composed_value_float = reinterpret_cast<const float*>(&composed_value);

    const unsigned base_sector_group_offset = dev_unique_x_sector_offsets[idx_offset];
    unsigned* hits_count_sector_group = hit_count + base_sector_group_offset;

    const unsigned current_hit_count = atomicAdd(hits_count_sector_group, 1);
    assert(current_hit_count < hit_offsets[base_sector_group_offset + 1] - hit_offsets[base_sector_group_offset]);

    const unsigned hit_index = hit_offsets[base_sector_group_offset] + current_hit_count;
    ut_pre_decoded_hits.sort_key(hit_index) = composed_value_float[0];

    // Raw bank hit index:
    // [raw bank 8 bits] [hit id inside raw bank 24 bits]
    assert(i < (0x1 << 24));
    const uint32_t raw_bank_hit_index = raw_bank_index << 24 | i;
    ut_pre_decoded_hits.index(hit_index) = raw_bank_hit_index;
  }
}

/**
 * Iterate over raw banks / hits and store only the Y coordinate,
 * and an uint32_t encoding the following:
 * raw_bank number and hit id inside the raw bank.
 * Let's refer to this array as raw_bank_hits.
 *
 * Kernel suitable for decoding from Allen layout
 */
__global__ void ut_pre_decode::ut_pre_decode(
  ut_pre_decode::Parameters parameters,
  const char* ut_boards,
  const char* ut_geometry,
  const unsigned* dev_ut_region_offsets,
  const unsigned* dev_unique_x_sector_layer_offsets,
  const unsigned* dev_unique_x_sector_offsets)
{
  const unsigned number_of_events = parameters.dev_number_of_events[0];
  const unsigned event_number = parameters.dev_event_list[blockIdx.x];
  const uint32_t event_offset = parameters.dev_ut_raw_input_offsets[event_number];

  const unsigned number_of_unique_x_sectors = dev_unique_x_sector_layer_offsets[4];
  const uint32_t* hit_offsets = parameters.dev_ut_hit_offsets + event_number * number_of_unique_x_sectors;
  uint32_t* hit_count = parameters.dev_ut_hit_count + event_number * number_of_unique_x_sectors;

  UT::PreDecodedHits ut_pre_decoded_hits {parameters.dev_ut_pre_decoded_hits,
                                          parameters.dev_ut_hit_offsets[number_of_events * number_of_unique_x_sectors]};

  const UTRawEvent raw_event(parameters.dev_ut_raw_input + event_offset);
  const UTBoards boards(ut_boards);
  const UTGeometry geometry(ut_geometry);

  for (unsigned raw_bank_index = threadIdx.x; raw_bank_index < raw_event.number_of_raw_banks;
       raw_bank_index += blockDim.x) {

    // Create UT raw bank from MEP layout
    const UTRawBank raw_bank = raw_event.getUTRawBank(raw_bank_index);
    pre_decode_raw_bank(
      dev_ut_region_offsets,
      dev_unique_x_sector_offsets,
      hit_offsets,
      geometry,
      boards,
      raw_bank,
      raw_bank_index,
      ut_pre_decoded_hits,
      hit_count);
  }
}

/**
 * Iterate over raw banks / hits and store only the Y coordinate,
 * and an uint32_t encoding the following:
 * raw_bank number and hit id inside the raw bank.
 * Let's refer to this array as raw_bank_hits.
 *
 * Kernel suitable for decoding from MEP layout
 */
__global__ void ut_pre_decode::ut_pre_decode_mep(
  ut_pre_decode::Parameters parameters,
  const char* ut_boards,
  const char* ut_geometry,
  const unsigned* dev_ut_region_offsets,
  const unsigned* dev_unique_x_sector_layer_offsets,
  const unsigned* dev_unique_x_sector_offsets)
{
  const uint32_t number_of_events = gridDim.x;
  const unsigned event_number = parameters.dev_event_list[blockIdx.x];
  const unsigned number_of_unique_x_sectors = dev_unique_x_sector_layer_offsets[4];
  const uint32_t* hit_offsets = parameters.dev_ut_hit_offsets + event_number * number_of_unique_x_sectors;
  uint32_t* hit_count = parameters.dev_ut_hit_count + event_number * number_of_unique_x_sectors;

  UT::PreDecodedHits ut_pre_decoded_hits {parameters.dev_ut_pre_decoded_hits,
                                          parameters.dev_ut_hit_offsets[number_of_events * number_of_unique_x_sectors]};

  const UTBoards boards(ut_boards);
  const UTGeometry geometry(ut_geometry);

  auto const number_of_ut_raw_banks = parameters.dev_ut_raw_input_offsets[0];

  for (unsigned raw_bank_index = threadIdx.x; raw_bank_index < number_of_ut_raw_banks; raw_bank_index += blockDim.x) {

    // Create UT raw bank from MEP layout
    const auto raw_bank = MEP::raw_bank<UTRawBank>(
      parameters.dev_ut_raw_input, parameters.dev_ut_raw_input_offsets, event_number, raw_bank_index);

    pre_decode_raw_bank(
      dev_ut_region_offsets,
      dev_unique_x_sector_offsets,
      hit_offsets,
      geometry,
      boards,
      raw_bank,
      raw_bank_index,
      ut_pre_decoded_hits,
      hit_count);
  }
}
