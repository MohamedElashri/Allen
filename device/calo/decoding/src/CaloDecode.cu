/*****************************************************************************\
* (c) Copyright 2021 CERN for the benefit of the LHCb Collaboration           *
*                                                                             *
* This software is distributed under the terms of the Apache License          *
* version 2 (Apache-2.0), copied verbatim in the file "LICENSE".              *
*                                                                             *
* In applying this licence, CERN does not waive the privileges and immunities *
* granted to it by virtue of its status as an Intergovernmental Organization  *
* or submit itself to any jurisdiction.                                       *
\*****************************************************************************/
#include <MEPTools.h>
#include <CaloDecode.cuh>

INSTANTIATE_ALGORITHM(calo_decode::calo_decode_t)

namespace {
  template<typename RawEvent, int decoding_version>
  __device__ void decode(
    const char* data,
    const uint32_t* offsets,
    const uint32_t* sizes,
    const uint32_t* types,
    unsigned const event_number,
    CaloDigit* digits,
    unsigned const number_of_digits,
    const CaloGeometry& geometry)
  {
    auto raw_event = RawEvent {data, offsets, sizes, types, event_number};

    for (unsigned bank_number = threadIdx.x; bank_number < raw_event.number_of_raw_banks; bank_number += blockDim.x) {
      auto raw_bank = raw_event.raw_bank(bank_number);

      if constexpr (decoding_version < 4) { // old decoding

        while (raw_bank.data < raw_bank.end) {
          uint32_t word = *raw_bank.data;
          uint16_t trig_size = word & 0x7F;
          uint16_t code = (word >> 14) & 0x1FF;

          // Skip header and trigger words
          raw_bank.data += 1 + (trig_size + 3) / 4;

          // pattern bits
          unsigned int pattern = *raw_bank.data;
          // Loop over all cards in this front-env sub-bank.
          uint32_t last_data = *(raw_bank.data + 1);
          raw_bank.data += 2;

          int16_t offset = 0;

          for (unsigned int bit_num = 0; 32 > bit_num; ++bit_num) {
            if (31 < offset) {
              offset -= 32;
              last_data = *raw_bank.data;
              raw_bank.data += 1;
            }
            int adc;
            if (0 == (pattern & (1 << bit_num))) { //.. short coding
              adc = ((last_data >> offset) & 0xF) - 8;
              offset += 4;
            }
            else {
              adc = ((last_data >> offset) & 0xFFF);
              if (24 == offset) adc &= 0xFF;
              if (28 == offset) adc &= 0xF; //== clean-up extra bits
              offset += 12;
              if (32 < offset) { //.. get the extra bits on next word
                last_data = *raw_bank.data;
                raw_bank.data += 1;
                offset -= 32;
                int temp = (last_data << (12 - offset)) & 0xFFF;
                adc += temp;
              }
              adc -= 256;
            }

            uint16_t index = geometry.channels[(code - geometry.code_offset) * geometry.card_channels + bit_num];
            // Ignore cells with invalid indices; these include LED diodes.
            if (index < number_of_digits) {
              digits[index].adc = adc;
            }
          }
        }
      }
      else {
        // else, use version 4 (big endian) or 5 (little endian) : New encoding
        // for run 3

        int32_t source_id = raw_bank.source_id;
        if (!((source_id >> 11) == 11)) continue; // Only decode Ecal banks

        auto raw_event_fiberCheck = RawEvent {data, offsets, sizes, types, event_number};
        auto raw_bank_fiberCheck = raw_event_fiberCheck.raw_bank(bank_number);

        auto get_data = [](uint32_t const* raw_data) {
          auto d = *raw_data;
          if constexpr (decoding_version == 4) { // big endian
            d = ((d >> 24) & 0x000000FF) | ((d >> 8) & 0x0000FF00) | ((d << 8) & 0x00FF0000) | ((d << 24) & 0xFF000000);
          }
          return d;
        };

        uint32_t pattern = *(raw_bank.data);

        int offset = 0;
        uint32_t lastData = pattern;
        uint32_t fibMask1 = 0xfff000ff;
        uint32_t fibMask2 = 0xf000fff0;
        uint32_t fibMask3 = 0xfff000;

        for (int ifeb = 0; ifeb < 3; ifeb++) {
          // First, remove 3 LLTs
          if (ifeb == 0) {
            raw_bank.data += 3;
            raw_bank_fiberCheck.data += 3;
          }
          lastData = get_data(raw_bank.data);

          int nADC = 0;
          bool isFiberOff = false;
          uint16_t code = geometry.getFEB(source_id, ifeb);
          uint16_t index_code = geometry.getFEBindex(source_id, ifeb);
          if (code == 0) continue; // No FEB linked to the TELL40 slot

          // ... and readout data
          for (unsigned int bitNum = 0; 32 > bitNum; bitNum++) {
            if (nADC % 8 == 0) { // Check fibers pattern, 1 fiber corresponds to 8 ADC (96b)
              if (offset == 32) raw_bank_fiberCheck.data += 1;
              uint32_t pattern1 = get_data(raw_bank_fiberCheck.data);
              raw_bank_fiberCheck.data += 1;
              uint32_t pattern2 = get_data(raw_bank_fiberCheck.data);
              raw_bank_fiberCheck.data += 1;
              uint32_t pattern3 = get_data(raw_bank_fiberCheck.data);
              if (pattern1 == fibMask1 && pattern2 == fibMask2 && pattern3 == fibMask3)
                isFiberOff = true;
              else
                isFiberOff = false;
            }
            if (31 < offset) {
              offset -= 32;
              raw_bank.data += 1;
              lastData = get_data(raw_bank.data);
            }

            int adc = 0;
            if (24 == offset)
              adc = (lastData & 0xff);
            else if (offset == 28)
              adc = (lastData & 0xf);
            else
              adc = ((lastData >> (20 - offset)) & 0xfff);

            if (28 == offset) { //.. get the extra bits on next word
              raw_bank.data += 1;
              lastData = get_data(raw_bank.data);

              int temp = (lastData >> (offset - 4)) & 0xFF;
              offset -= 32;
              adc = (adc << 8) + temp;
            }
            if (24 == offset) { //.. get the extra bits on next word
              raw_bank.data += 1;
              lastData = get_data(raw_bank.data);
              int temp = (lastData >> (offset + 4)) & 0xF;
              offset -= 32;
              adc = (adc << 4) + temp;
            }
            offset += 12;
            adc -= 256;
            ++nADC;

            uint16_t index = geometry.channels[(index_code) *geometry.card_channels + bitNum];

            // Ignore cells with invalid indices; these include LED diodes.
            if (index < number_of_digits && !isFiberOff) {
              digits[index].adc = adc;
            }
          }
        }
      } // end Run 3 decoding
    }
  }
} // namespace

// Decode dispatch
template<bool mep_layout, int decoding_version>
__global__ void calo_decode_dispatch(calo_decode::Parameters parameters, const char* raw_ecal_geometry)
{
  unsigned const event_number = parameters.dev_event_list[blockIdx.x];

  // ECal
  auto ecal_geometry = CaloGeometry(raw_ecal_geometry);
  auto const ecal_digits_offset = parameters.dev_ecal_digits_offsets[event_number];

  decode<Calo::RawEvent<mep_layout>, decoding_version>(
    parameters.dev_ecal_raw_input,
    parameters.dev_ecal_raw_input_offsets,
    parameters.dev_ecal_raw_input_sizes,
    parameters.dev_ecal_raw_input_types,
    event_number,
    &parameters.dev_ecal_digits[ecal_digits_offset],
    parameters.dev_ecal_digits_offsets[event_number + 1] - ecal_digits_offset,
    ecal_geometry);
}

void calo_decode::calo_decode_t::set_arguments_size(
  ArgumentReferences<Parameters> arguments,
  const RuntimeOptions&,
  const Constants&,
  const HostBuffers&) const
{
  set_size<dev_ecal_digits_t>(arguments, first<host_ecal_number_of_digits_t>(arguments));
}

void calo_decode::calo_decode_t::operator()(
  const ArgumentReferences<Parameters>& arguments,
  const RuntimeOptions& runtime_options,
  const Constants& constants,
  HostBuffers&,
  const Allen::Context& context) const
{
  Allen::memset_async<dev_ecal_digits_t>(arguments, 0x7F, context);
  auto const bank_version = first<host_raw_bank_version_t>(arguments);

  // Ensure the bank version is supported
  if (bank_version > 5) {
    throw StrException("Calo bank version not supported (" + std::to_string(bank_version) + ")");
  }

  const auto bank_geom_compatibility_check = [](const int bank_version, const int geom_version) {
    if (bank_version <= 3 && geom_version <= 3) {
      return true;
    }
    else if ((bank_version == 4 || bank_version == 5) && geom_version == 4) {
      return true;
    }
    return false;
  };

  const auto geom_version = CaloGeometry(constants.host_ecal_geometry.data()).geom_version;
  if (!bank_geom_compatibility_check(bank_version, geom_version)) {
    throw StrException(
      "Calo bank version - geometry version mismatch (bank version " + std::to_string(bank_version) +
      ", calo geometry version " + std::to_string(geom_version) + ")");
  }

  auto fn =
    runtime_options.mep_layout ?
      (bank_version == 4 ? calo_decode_dispatch<true, 4> :
                           (bank_version == 5 ? calo_decode_dispatch<true, 5> : calo_decode_dispatch<true, 3>) ) :
      (bank_version == 4 ? calo_decode_dispatch<false, 4> :
                           (bank_version == 5 ? calo_decode_dispatch<false, 5> : calo_decode_dispatch<false, 3>) );

  global_function(fn)(dim3(size<dev_event_list_t>(arguments)), dim3(property<block_dim_x_t>().get()), context)(
    arguments, constants.dev_ecal_geometry);
}
