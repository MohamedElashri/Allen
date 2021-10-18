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
    CaloGeometry const& geometry)
  {
    auto raw_event = RawEvent {data, offsets, sizes, types, event_number};
    auto raw_event_fiberCheck = RawEvent {data, offsets, sizes, event_number};

    bool log = false;
    bool logLLT = true;
    bool logF = false;
    bool log218_0 = false; // true;

    for (unsigned bank_number = threadIdx.x; bank_number < raw_event.number_of_raw_banks; bank_number += blockDim.x) {
      auto raw_bank = raw_event.bank(bank_number);

      int32_t source_id = raw_bank.source_id;
      if (!((source_id >> 11) == 11)) continue; // Only decode Ecal banks

      uint32_t lastData = *(raw_bank.data);
      auto raw_bank_fiberCheck = raw_event_fiberCheck.bank(bank_number);

      int32_t source_id = raw_bank.source_id;

      auto get_data = [](uint32_t* const raw_data) {
        auto d = *raw_data;
        if constexpr (decoding_version == 1) {
          d = ((d >> 24) & 0x000000FF) | ((d >> 8) & 0x0000FF00) | ((d << 8) & 0x00FF0000) | ((d << 24) & 0xFF000000);
        }
        return d;
      };

      uint32_t pattern = *(raw_bank.data);
      if (logF) printf("First pattern = %03x\n", pattern);

      int offset = 0;
      uint32_t lastData = pattern;
      uint32_t fibMask1 = 0xfff000ff;
      uint32_t fibMask2 = 0xf000fff0;
      uint32_t fibMask3 = 0xfff000;

      for (int ifeb = 0; ifeb < 3; ifeb++) {
        // First, remove 3 LLTs
        if (ifeb == 0) {
          uint32_t llt1 = get_data(raw_bank.data);
          if (logLLT) printf("llt_1 = %03x\n", llt1);

          raw_bank.data += 1;
          uint32_t llt2 = get_data(raw_bank.data);
          if (logLLT) printf("llt_2 = %03x\n", llt2);

          raw_bank.data += 1;
          uint32_t llt3 = get_data(raw_bank.data);
          if (logLLT) printf("llt_3 = %03x\n", llt3);

          raw_bank.data += 1;
          raw_bank_fiberCheck.data += 3;
        }
        lastData = get_data(raw_bank.data);
        if (log) printf("%03x\n", lastData);

        int nADC = 0;
        bool isFiberOff = false;
        uint16_t code = geometry.getFEB(source_id, ifeb);
        uint16_t index_code = geometry.getFEBindex(source_id, ifeb);
        if (code == 0) continue; // No FEB linked to the TELL40 slot

        // ... and readout data
        for (unsigned int bitNum = 0; 32 > bitNum; bitNum++) {
          //	  if (logF) printf("bitNum = %u\n",bitNum);
          if (nADC % 8 == 0) { // Check fibers pattern, 1 fiber corresponds to 8 ADC (96b)
            // uint32_t pattern0 = *(raw_bank_fiberCheck.data);

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
          //	  if (logF) printf("isFiberOff = %u\n",isFiberOff);

          if (31 < offset) {
            offset -= 32;
            raw_bank.data += 1;
            lastData = get_data(raw_bank.data);
            if (logF) printf("%03x\n", lastData);
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
            if (logF) printf("%03x\n", lastData);

            int temp = (lastData >> (offset - 4)) & 0xFF;
            offset -= 32;
            adc = (adc << 8) + temp;
          }
          if (24 == offset) { //.. get the extra bits on next word
            raw_bank.data += 1;
            lastData = get_data(raw_bank.data);
            if (logF) printf("%03x\n", lastData);
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
            if (adc > 500 && adc < 100000) {
              printf(
                ">500    index = %u, ADC = %d , sourceID = %u, ife = %u,  code = %u,  decoding version = %u, adc = "
                "%03x\n",
                index,
                adc,
                source_id,
                ifeb,
                code,
                decoding_version,
                adc + 256);
            }
            if (log218_0 && code == 218 && bitNum == 0)
              printf(
                "index = %u, code = %u, bitNum = %u, ADC = %d, ADChex = %03x, sourceID = %u, ife = %u,  decoding "
                "version = %u\n",
                index,
                code,
                bitNum,
                adc,
                adc + 256,
                source_id,
                ifeb,
                decoding_version);
            // if (logF) printf("index = %u, code = %u, bitNum = %u, ADC = %d, ADChex = %03x, sourceID = %u, ife = %u,
            // decoding version = %u\n", index, code, bitNum, adc, adc+256,source_id, ifeb, decoding_version);
            if (log && bitNum == 0)
              printf(
                " |  SourceID : %u |  FeBoard : %u |  Channel : %u |  ADC value = %d %d\n",
                source_id,
                code,
                bitNum,
                adc,
                adc + 256);

            digits[index].adc = adc;
            // } else {
            //	if (logF) printf("index = %u, number_of_digits =  %u\n",index,number_of_digits);
          }
        }
      }
    }
  }
} // namespace

// Decode dispatch
template<bool mep_layout>
__global__ void
calo_decode_dispatch(calo_decode::Parameters parameters, int decoding_version, const char* raw_ecal_geometry)
{
  unsigned const event_number = parameters.dev_event_list[blockIdx.x];

  // ECal
  auto ecal_geometry = CaloGeometry(raw_ecal_geometry);
  auto const ecal_digits_offset = parameters.dev_ecal_digits_offsets[event_number];

  auto fun = decoding_version == 2 ? decode<Calo::RawEvent<mep_layout>, 2> : decode<Calo::RawEvent<mep_layout>, 1>;
  fun(
    parameters.dev_ecal_raw_input,
    parameters.dev_ecal_raw_input_offsets,
    parameters.dev_ecal_raw_input_sizes,
    event_number,
    &parameters.dev_ecal_digits[ecal_digits_offset],
    parameters.dev_ecal_digits_offsets[event_number + 1] - ecal_digits_offset,
    ecal_geometry);
}

INSTANTIATE_ALGORITHM(calo_decode::calo_decode_t)

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
  initialize<dev_ecal_digits_t>(arguments, 0x7F, context);

  auto const bank_version = first<host_raw_bank_version_t>(arguments);
  //  printf("bank_version = %u\n",bank_version);

  if (runtime_options.mep_layout) {
    global_function(calo_decode_dispatch<true>)(
      dim3(size<dev_event_list_t>(arguments)), dim3(property<block_dim_x_t>().get()), context)(
      arguments, bank_version, constants.dev_ecal_geometry);
  }
  else {
    global_function(calo_decode_dispatch<false>)(
      dim3(size<dev_event_list_t>(arguments)), dim3(property<block_dim_x_t>().get()), context)(
      arguments, bank_version, constants.dev_ecal_geometry);
  }
}
