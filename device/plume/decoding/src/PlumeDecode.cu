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
#include <PlumeDecode.cuh>
#include <BankTypes.h>

INSTANTIATE_ALGORITHM(plume_decode::plume_decode_t)

namespace {
  template<typename RawEvent, int decoding_version>
  __device__ void decode(
    const char* data,
    const uint32_t* offsets,
    const uint32_t* sizes,
    const uint32_t* types,
    unsigned const event_number,
    Plume_* pl)
  {

    auto raw_event = RawEvent {data, offsets, sizes, types, event_number};

    for (unsigned bank_number = threadIdx.x; bank_number < raw_event.number_of_raw_banks; bank_number += blockDim.x) {

      auto raw_bank = raw_event.raw_bank(bank_number);
      int32_t source_id = raw_bank.source_id;

      if (raw_bank.type != LHCb::RawBank::BankType::Plume) {
        continue;
      }

      if constexpr (decoding_version == 2 || decoding_version == 3 || decoding_version == 4) {

        int n_ch = 22;
        if constexpr (decoding_version == 2) {
          if (source_id != 0x5001) continue;
        }
        else {
          if (source_id != 0x5001 and source_id != 0x5002) continue;
        }

        uint32_t ovr_thb = {0}; // overthreshold bits: 1 bit objects for the n_ch channels

        int n_bank = int(source_id & 0x3);

        for (int ch = 0; ch < n_ch; ch++) {

          uint32_t new_word = raw_bank.data[ch];

          if constexpr (decoding_version == 3) new_word = __bswap(new_word);

          ovr_thb |= (new_word >> 31) << ch;

          auto pedestal_sub_adc = (unsigned int) ((0x7ffff000 & new_word) >> 12);

          pl->ADC_counts.at(ch + n_ch * (n_bank - 1)) = static_cast<float>(pedestal_sub_adc) / 128.f;
        }

        pl->ovr_th[n_bank - 1] = ovr_thb;
      }

      else if constexpr (decoding_version == 1) {

        if (source_id != 0x5001) continue;

        pl->ovr_th[0] = __brev(__bswap(*(raw_bank.data++)));
        pl->ovr_th[1] = __brev(__bswap(*(raw_bank.data++)));

        for (int k = 0; k < 64; k++) {
          int i = k * 12 / 32;
          int j = k * 12 % 32;
          uint32_t value =
            ((static_cast<uint64_t>(__bswap(__brev(raw_bank.data[i + 1]))) << 32 | __bswap(__brev(raw_bank.data[i]))) >>
             j) &
            0xfff;
          pl->ADC_counts.at(k) = static_cast<float>(__brev(value) >> (32 - 12));
        }
      }
    }
  }
} // namespace

template<bool mep_layout, int decoding_version>
__global__ void plume_decode_kernel(plume_decode::Parameters parameters)
{
  unsigned const event_number = parameters.dev_event_list[blockIdx.x];

  decode<Plume::RawEvent<mep_layout>, decoding_version>(
    parameters.dev_plume_raw_input,
    parameters.dev_plume_raw_input_offsets,
    parameters.dev_plume_raw_input_sizes,
    parameters.dev_plume_raw_input_types,
    event_number,
    &parameters.dev_plume[event_number]);
}

void plume_decode::plume_decode_t::set_arguments_size(
  ArgumentReferences<Parameters> arguments,
  const RuntimeOptions&,
  const Constants&) const
{
  set_size<dev_plume_t>(arguments, first<host_number_of_events_t>(arguments));
}

void plume_decode::plume_decode_t::operator()(
  const ArgumentReferences<Parameters>& arguments,
  const RuntimeOptions& runtime_options,
  const Constants& constants,
  const Allen::Context& context) const
{
  (void) constants;
  Allen::memset_async<dev_plume_t>(arguments, 0x7F, context);
  auto const bank_version = first<host_raw_bank_version_t>(arguments);
  if (bank_version < 0) return;

  auto f_plume_decode_kernel =
    runtime_options.mep_layout ?
      (bank_version == 4 ?
         plume_decode_kernel<true, 4> :
         (bank_version == 3 ? plume_decode_kernel<true, 3> :
                              (bank_version == 2 ? plume_decode_kernel<true, 2> : plume_decode_kernel<true, 1>) )) :
      (bank_version == 4 ?
         plume_decode_kernel<false, 4> :
         (bank_version == 3 ? plume_decode_kernel<false, 3> :
                              (bank_version == 2 ? plume_decode_kernel<false, 2> : plume_decode_kernel<false, 1>) ));

  global_function(f_plume_decode_kernel)(dim3(size<dev_event_list_t>(arguments)), dim3(m_block_dim_x), context)(
    arguments);
}
