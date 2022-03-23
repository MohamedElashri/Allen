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
#pragma once

#include <type_traits>
#include "BackendCommon.h"
#include "MEPTools.h"

namespace Calo {

  struct RawBank {
    uint32_t source_id = 0;
    uint32_t const* data = nullptr;
    uint32_t const* end = nullptr;
    uint8_t const type;

    // For Allen format
    __device__ __host__ RawBank(const char* raw_bank, const uint16_t s, const uint8_t t) :
      RawBank {*(uint32_t*) raw_bank, raw_bank + sizeof(uint32_t), s, t}
    {}

    // For MEP format
    __device__ __host__ RawBank(const uint32_t sid, const char* fragment, const uint16_t s, const uint8_t t) :
      source_id {sid}, data {reinterpret_cast<uint32_t const*>(fragment)}, end {reinterpret_cast<uint32_t const*>(
                                                                                                                  fragment + s)}, type{t}
    {
      assert(s % sizeof(uint32_t) == 0);
    }
  };

  template<bool mep_layout>
  struct RawEvent {

    uint32_t number_of_raw_banks = 0;
    const char* data = nullptr;
    const uint32_t* offsets = nullptr;
    typename std::conditional_t<mep_layout, uint32_t const, uint16_t const>* sizes = nullptr;
    typename std::conditional_t<mep_layout, uint32_t const, uint8_t const>* types = nullptr;
    const unsigned event = 0;

    // For Allen format
    __device__ __host__ RawEvent(char const* d, uint32_t const* o, uint32_t const* s, uint32_t const* t, unsigned const event_number) :
      offsets {o}, event {event_number}
    {
      if constexpr (mep_layout) {
        data = d;
        number_of_raw_banks = MEP::number_of_banks(o);
        sizes = s;
        types = t;
      }
      else {
        data = d + offsets[event];
        number_of_raw_banks = reinterpret_cast<uint32_t const*>(data)[0];
        sizes = Allen::bank_sizes(s, event);
        types = Allen::bank_types(s, event);
      }
    }

    __device__ __host__ RawBank raw_bank(unsigned const n) const
    {
      if constexpr (mep_layout) {
        return MEP::raw_bank<RawBank>(data, offsets, sizes, types, event, n);
      }
      else {
        uint32_t const* bank_offsets = reinterpret_cast<uint32_t const*>(data) + 1;
        return RawBank {data + (number_of_raw_banks + 2) * sizeof(uint32_t) + bank_offsets[n], sizes[n], types[n]};
      }
    }
  };
} // namespace Calo
