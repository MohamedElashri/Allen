/*****************************************************************************\
* (c) Copyright 2021 CERN for the benefit of the LHCb Collaboration           *
\*****************************************************************************/

#pragma once

#include "CaloRawEvent.cuh"
#include "CaloRawBanks.cuh"
#include "CaloGeometry.cuh"
#include "CaloDigit.cuh"
#include "DeviceAlgorithm.cuh"

namespace {
  template<typename RawEvent>
  __device__ void decode(
    const char* event_data,
    const uint32_t* event_offsets,
    unsigned const event_number,
    CaloDigit* digits,
    unsigned const number_of_digits,
    CaloGeometry const& geometry)
  {
    auto raw_event = RawEvent {event_data, event_offsets};
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

          uint16_t index = geometry.channels[(code - geometry.code_offset) * geometry.card_channels + bit_num];
          // Ignore cells with invalid indices; these include LED diodes.
          if (index < number_of_digits) {
            digits[index].adc = adc;
          }
        }
      }
    }
  }
}

namespace calo_decode {
  struct Parameters {
    HOST_INPUT(host_number_of_events_t, unsigned) host_number_of_events;
    HOST_INPUT(host_ecal_number_of_digits_t, unsigned) host_ecal_number_digits;
    HOST_INPUT(host_hcal_number_of_digits_t, unsigned) host_hcal_number_digits;
    DEVICE_INPUT(dev_event_list_t, unsigned) dev_event_list;
    DEVICE_INPUT(dev_ecal_raw_input_t, char) dev_ecal_raw_input;
    DEVICE_INPUT(dev_ecal_raw_input_offsets_t, unsigned) dev_ecal_raw_input_offsets;
    DEVICE_INPUT(dev_hcal_raw_input_t, char) dev_hcal_raw_input;
    DEVICE_INPUT(dev_hcal_raw_input_offsets_t, unsigned) dev_hcal_raw_input_offsets;
    DEVICE_INPUT(dev_ecal_digits_offsets_t, unsigned) dev_ecal_digits_offsets;
    DEVICE_INPUT(dev_hcal_digits_offsets_t, unsigned) dev_hcal_digits_offsets;
    DEVICE_OUTPUT(dev_ecal_digits_t, CaloDigit) dev_ecal_digits;
    DEVICE_OUTPUT(dev_hcal_digits_t, CaloDigit) dev_hcal_digits;
    PROPERTY(block_dim_x_t, "block_dim_x", "block dimension X", unsigned) block_dim;
  };

  struct check_digits : public Allen::contract::Postcondition {
    void operator()(
      const ArgumentReferences<Parameters>&,
      const RuntimeOptions&,
      const Constants&,
      const Allen::Context&) const;
  };

  // Decode dispatch
  template<bool MEP>
  __global__ void calo_decode(
    calo_decode::Parameters parameters,
    const char* raw_ecal_geometry,
    const char* raw_hcal_geometry)
  {
    using RawEvent = std::conditional_t<MEP, CaloMepEvent, CaloRawEvent>;

    unsigned const event_number = parameters.dev_event_list[blockIdx.x];

    // ECal
    auto ecal_geometry = CaloGeometry(raw_ecal_geometry);
    auto const ecal_digits_offset = parameters.dev_ecal_digits_offsets[event_number];
    decode<RawEvent>(
      parameters.dev_ecal_raw_input,
      parameters.dev_ecal_raw_input_offsets,
      event_number,
      &parameters.dev_ecal_digits[ecal_digits_offset],
      parameters.dev_ecal_digits_offsets[event_number + 1] - ecal_digits_offset,
      ecal_geometry);

    // HCal
    auto hcal_geometry = CaloGeometry(raw_hcal_geometry);
    auto const hcal_digits_offset = parameters.dev_hcal_digits_offsets[event_number];
    decode<RawEvent>(
      parameters.dev_hcal_raw_input,
      parameters.dev_hcal_raw_input_offsets,
      event_number,
      &parameters.dev_hcal_digits[hcal_digits_offset],
      parameters.dev_hcal_digits_offsets[event_number + 1] - hcal_digits_offset,
      hcal_geometry);
  }

  // Algorithm
  struct calo_decode_t : public DeviceAlgorithm, Parameters {

    using contracts = std::tuple<check_digits>;

    void set_arguments_size(
      ArgumentReferences<Parameters> arguments,
      const RuntimeOptions& runtime_options,
      const Constants&,
      const HostBuffers&) const;

    void operator()(
      const ArgumentReferences<Parameters>& arguments,
      const RuntimeOptions& runtime_options,
      const Constants& constants,
      HostBuffers&,
      Allen::Context const&) const;

  private:
    Property<block_dim_x_t> m_block_dim_x {this, 32};
  };
} // namespace calo_decode
