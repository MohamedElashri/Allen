
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

    auto bit_shif = [&](uint32_t w) {
      return ((w & 0xFF) << 24) | ((w & 0xFF00) << 8) | ((w & 0xFF0000) >> 8) | ((w & 0xFF000000) >> 24);
    };

    auto raw_event = RawEvent {data, offsets, sizes, types, event_number};

    for (unsigned bank_number = threadIdx.x; bank_number < raw_event.number_of_raw_banks; bank_number += blockDim.x) {
      auto raw_bank = raw_event.raw_bank(bank_number);

      int32_t source_id = raw_bank.source_id;

      if (raw_bank.type != LHCb::RawBank::BankType::Plume) {
        continue;
      }

      if (source_id != 0x5001) continue;

      uint32_t word = *(raw_bank.data);
      auto new_word = bit_shif(word);
      pl->ovr_th = pl->ovr_th << 32;
      pl->ovr_th |= new_word;
      raw_bank.data += 1;
      uint32_t word2 = *(raw_bank.data);
      auto new_word2 = bit_shif(word2);
      pl->ovr_th = pl->ovr_th << 32;
      pl->ovr_th |= new_word2;

      raw_bank.data += 1;

      struct one_bit {
        unsigned one : 1;
      };
      one_bit board_ch[768];

      for (int wrd = 0; wrd < 24; wrd++) {
        uint32_t elem = *(raw_bank.data);
        auto new_elem = bit_shif(elem);

        for (int e = 0; e < 32; e++) {
          board_ch[(31 - e) + 32 * wrd].one = ((new_elem & (1 << (e))) >> (e));
        }

        raw_bank.data += 1;
      }

      for (int k = 0; k < 64; k++) {
        for (int pos_bit = 0; pos_bit < 12; pos_bit++) {
          pl->ADC_counts[k].x = pl->ADC_counts[k].x << 1 | (board_ch[12 * k + pos_bit].one);
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
    &parameters.dev_plume[0]);
}

void plume_decode::plume_decode_t::set_arguments_size(
  ArgumentReferences<Parameters> arguments,
  const RuntimeOptions&,
  const Constants&,
  const HostBuffers&) const
{
  set_size<dev_plume_t>(arguments, first<host_number_of_events_t>(arguments));
}

void plume_decode::plume_decode_t::operator()(
  const ArgumentReferences<Parameters>& arguments,
  const RuntimeOptions& runtime_options,
  const Constants& constants,
  HostBuffers&,
  const Allen::Context& context) const
{
  (void) constants;
  Allen::memset_async<dev_plume_t>(arguments, 0x7F, context);
  auto const bank_version = first<host_raw_bank_version_t>(arguments);

  auto f_plume_decode_kernel =
    runtime_options.mep_layout ?
      (bank_version == 4 ? plume_decode_kernel<true, 4> :
                           (bank_version == 5 ? plume_decode_kernel<true, 5> : plume_decode_kernel<true, 1>) ) :
      (bank_version == 4 ? plume_decode_kernel<false, 4> :
                           (bank_version == 5 ? plume_decode_kernel<false, 5> : plume_decode_kernel<false, 1>) );

  global_function(f_plume_decode_kernel)(
    dim3(size<dev_event_list_t>(arguments)), dim3(property<block_dim_x_t>().get()), context)(arguments);
}
