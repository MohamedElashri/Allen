/*****************************************************************************\
* (c) Copyright 2018-2020 CERN for the benefit of the LHCb Collaboration      *
\*****************************************************************************/
#pragma once

#include <stdint.h>
#include "BackendCommon.h"

template<int decoding_version>
struct UTRawBank {
  uint32_t sourceID;
  std::array<uint32_t, 6> number_of_hits {0, 0, 0, 0, 0, 0};
  const uint16_t* data = nullptr;

  static_assert(decoding_version == -1 || decoding_version == 3 || decoding_version == 4);

  __device__ __host__ UTRawBank(const char* ut_raw_bank, const uint32_t size) :
    UTRawBank {reinterpret_cast<const uint32_t*>(ut_raw_bank)[0], ut_raw_bank + sizeof(uint32_t), ut_raw_bank + size}
  {}

  __device__ __host__
  UTRawBank(const uint32_t sID, const char* ut_fragment, [[maybe_unused]] const char* ut_fragment_end)
  {
    sourceID = sID;
    auto p = reinterpret_cast<const uint32_t*>(ut_fragment);
    if constexpr (decoding_version == 3) {
      number_of_hits[0] = *p & 0x0000FFFFU;
      p += 1;
      data = reinterpret_cast<const uint16_t*>(p);
    }
    else if constexpr (decoding_version == 4) {
      if ((ut_fragment_end - ut_fragment) >= static_cast<long>(6 * sizeof(uint32_t))) {
        bool bad = false;
        auto add_to_hits = [this, &bad](uint32_t n_hits_in_lane, uint32_t lane_index) {
          if (n_hits_in_lane == 255)
            bad = true;
          else
            number_of_hits[lane_index] = n_hits_in_lane;
        };
        add_to_hits((*p & 0xFFU) >> 0U, 4U);
        add_to_hits((*p & 0xFF00U) >> 8U, 5U);
        p += 1;
        add_to_hits((*p & 0xFFU) >> 0U, 0U);
        add_to_hits((*p & 0xFF00U) >> 8U, 1U);
        add_to_hits((*p & 0xFF0000U) >> 16U, 2U);
        add_to_hits((*p & 0xFF000000U) >> 24U, 3U);

        if (bad) {
          number_of_hits = {0, 0, 0, 0, 0, 0};
        }
        else {
          p += 1;
          data = reinterpret_cast<const uint16_t*>(p);
        }
      }
    }
  }

  __device__ __host__ uint32_t get_n_hits() const
  {
    return number_of_hits[0] + number_of_hits[1] + number_of_hits[2] + number_of_hits[3] + number_of_hits[4] +
           number_of_hits[5];
  }
};

struct UTRawEvent {
  uint32_t number_of_raw_banks;
  const uint32_t* raw_bank_offsets;
  const char* data;

  __device__ __host__ UTRawEvent(const char* event)
  {
    const char* p = event;
    number_of_raw_banks = *(reinterpret_cast<const uint32_t*>(p));
    p += sizeof(uint32_t);
    raw_bank_offsets = reinterpret_cast<const uint32_t*>(p);
    p += (number_of_raw_banks + 1) * sizeof(uint32_t);
    data = p;
  }

  template<int decoding_version>
  __device__ __host__ UTRawBank<decoding_version> getUTRawBank(const uint32_t& index) const
  {
    const uint32_t offset = raw_bank_offsets[index];
    return UTRawBank<decoding_version>(data + offset, raw_bank_offsets[index + 1] - offset);
  }
};
