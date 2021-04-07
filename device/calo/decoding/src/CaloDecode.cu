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
#include <CaloConstants.cuh>
#include <CaloDecode.cuh>

// TODO thinks about blocks/threads etc. 1 block per fragment might be best for coalesced memory acces.

template<typename Event>
__device__ void decode(
  const char* event_data,
  const uint32_t* event_offsets,
  unsigned const event_number,
  CaloDigit* digits,
  [[maybe_unused]] unsigned const number_of_digits,
  CaloGeometry const& geometry)
{
  auto raw_event = Event {event_data, event_offsets};
  for (unsigned bank_number = threadIdx.x; bank_number < raw_event.number_of_raw_banks; bank_number += blockDim.x) {
    auto raw_bank = raw_event.bank(event_number, bank_number);
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

        uint16_t index = geometry.channels[(code - geometry.code_offset) * Calo::Constants::card_channels + bit_num];
        // Ignore cells with invalid indices; these include LED diodes.
        if (index < number_of_digits) {
          digits[index].adc = adc;
        }
      }
    }
  }
}

__global__ void calo_decode::calo_decode(
  calo_decode::Parameters parameters,
  const char* raw_ecal_geometry,
  const char* raw_hcal_geometry)
{
  unsigned const event_number = parameters.dev_event_list[blockIdx.x];

  // ECal
  auto ecal_geometry = CaloGeometry(raw_ecal_geometry);
  auto const ecal_digits_offset = parameters.dev_ecal_digits_offsets[event_number];
  decode<CaloRawEvent>(
    parameters.dev_ecal_raw_input,
    parameters.dev_ecal_raw_input_offsets,
    event_number,
    &parameters.dev_ecal_digits[ecal_digits_offset],
    parameters.dev_ecal_digits_offsets[event_number + 1] - ecal_digits_offset,
    ecal_geometry);

  // HCal
  auto hcal_geometry = CaloGeometry(raw_hcal_geometry);
  auto const hcal_digits_offset = parameters.dev_hcal_digits_offsets[event_number];
  decode<CaloRawEvent>(
    parameters.dev_hcal_raw_input,
    parameters.dev_hcal_raw_input_offsets,
    event_number,
    &parameters.dev_hcal_digits[hcal_digits_offset],
    parameters.dev_hcal_digits_offsets[event_number + 1] - hcal_digits_offset,
    hcal_geometry);
}

__global__ void calo_decode::calo_decode_mep(
  calo_decode::Parameters parameters,
  const char* raw_ecal_geometry,
  const char* raw_hcal_geometry)
{
  unsigned const event_number = parameters.dev_event_list[blockIdx.x];

  // ECal
  auto ecal_geometry = CaloGeometry {raw_ecal_geometry};
  auto const ecal_digits_offset = parameters.dev_ecal_digits_offsets[event_number];
  decode<CaloMepEvent>(
    parameters.dev_ecal_raw_input,
    parameters.dev_ecal_raw_input_offsets,
    event_number,
    &parameters.dev_ecal_digits[ecal_digits_offset],
    parameters.dev_ecal_digits_offsets[event_number + 1] - ecal_digits_offset,
    ecal_geometry);

  // HCal
  auto hcal_geometry = CaloGeometry {raw_hcal_geometry};
  auto const hcal_digits_offset = parameters.dev_hcal_digits_offsets[event_number];
  decode<CaloMepEvent>(
    parameters.dev_hcal_raw_input,
    parameters.dev_hcal_raw_input_offsets,
    event_number,
    &parameters.dev_hcal_digits[hcal_digits_offset],
    parameters.dev_hcal_digits_offsets[event_number + 1] - hcal_digits_offset,
    hcal_geometry);
}

void calo_decode::calo_decode_t::set_arguments_size(
  ArgumentReferences<Parameters> arguments,
  const RuntimeOptions&,
  const Constants&,
  const HostBuffers&) const
{
  set_size<dev_ecal_digits_t>(arguments, first<host_ecal_number_of_digits_t>(arguments));
  set_size<dev_hcal_digits_t>(arguments, first<host_hcal_number_of_digits_t>(arguments));
}

void calo_decode::calo_decode_t::operator()(
  const ArgumentReferences<Parameters>& arguments,
  const RuntimeOptions& runtime_options,
  const Constants& constants,
  HostBuffers& host_buffers,
  const Allen::Context& context) const
{
  initialize<dev_ecal_digits_t>(arguments, SHRT_MAX, context);
  initialize<dev_hcal_digits_t>(arguments, SHRT_MAX, context);

  if (runtime_options.mep_layout) {
    global_function(calo_decode_mep)(
      dim3(size<dev_event_list_t>(arguments)), dim3(property<block_dim_x_t>().get()), context)(
      arguments, constants.dev_ecal_geometry, constants.dev_hcal_geometry);
  }
  else {
    global_function(calo_decode)(
      dim3(size<dev_event_list_t>(arguments)), dim3(property<block_dim_x_t>().get()), context)(
      arguments, constants.dev_ecal_geometry, constants.dev_hcal_geometry);
  }

  if (runtime_options.do_check) {
    safe_assign_to_host_buffer<dev_ecal_digits_offsets_t>(host_buffers.host_ecal_digits_offsets, arguments, context);
    safe_assign_to_host_buffer<dev_hcal_digits_offsets_t>(host_buffers.host_hcal_digits_offsets, arguments, context);
    safe_assign_to_host_buffer<dev_ecal_digits_t>(host_buffers.host_ecal_digits, arguments, context);
    safe_assign_to_host_buffer<dev_hcal_digits_t>(host_buffers.host_hcal_digits, arguments, context);
  }
}
