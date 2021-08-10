/*****************************************************************************\
* (c) Copyright 2018-2020 CERN for the benefit of the LHCb Collaboration      *
\*****************************************************************************/
#pragma once

#include <stdint.h>

template<int decoding_version>
struct UTRawBank {
  uint32_t sourceID;
  std::array<uint32_t, 6> number_of_hits {0, 0, 0, 0, 0, 0};
  uint16_t* data;

  static_assert(decoding_version == -1 || decoding_version == 3 || decoding_version == 4);

  __device__ __host__ UTRawBank(const char* ut_raw_bank, const uint32_t size)
  {
    uint32_t* p = (uint32_t*) ut_raw_bank;
    sourceID = *p;
    p += 1;
    if constexpr (decoding_version == 3) {
      number_of_hits[0] = *p & 0x0000FFFFU;
    }
    else if constexpr (decoding_version == 4) {
      bool bad = false;
      auto add_to_hits = [this, &bad](uint32_t&& n_hits_in_lane, uint32_t&& lane_index) {
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
      // the header contains garbage if there are actually no words to decode (and there are always 6 words -- the word
      // is 0 if there are no hits in the lane)
      // also protect against corrupt events
      if (((size - 1 * sizeof(uint32_t)) < sizeof(uint32_t) * 6) || bad) number_of_hits = {0, 0, 0, 0, 0, 0};
    }
    p += 1;
    data = (uint16_t*) p;
  }

  __device__ __host__
  UTRawBank(const uint32_t sID, const char* ut_fragment, [[maybe_unused]] const char* ut_fragment_end)
  {
    sourceID = sID;
    uint32_t* p = (uint32_t*) ut_fragment;
    if constexpr (decoding_version == 3) {
      number_of_hits[0] = *p & 0x0000FFFFU;
    }
    else if constexpr (decoding_version == 4) {
      bool bad = false;
      auto add_to_hits = [this, &bad](uint32_t&& n_hits_in_lane, uint32_t&& lane_index) {
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

      if (((ut_fragment_end - ut_fragment) < static_cast<long>(6 * sizeof(uint32_t))) || bad)
        number_of_hits = {0, 0, 0, 0, 0, 0};
    }
    p += 1;
    data = (uint16_t*) p;
  }

  __device__ __host__ uint32_t get_n_hits() const
  {
    return number_of_hits[0] + number_of_hits[1] + number_of_hits[2] + number_of_hits[3] + number_of_hits[4] +
           number_of_hits[5];
  }
};

struct UTRawEvent {
  uint32_t number_of_raw_banks;
  uint32_t* raw_bank_offsets;
  char* data;

  __device__ __host__ UTRawEvent(const char* event)
  {
    const char* p = event;
    number_of_raw_banks = *((uint32_t*) p);
    p += sizeof(uint32_t);
    raw_bank_offsets = (uint32_t*) p;
    p += (number_of_raw_banks + 1) * sizeof(uint32_t);
    data = (char*) p;
  }

  template<int decoding_version>
  __device__ __host__ UTRawBank<decoding_version> getUTRawBank(const uint32_t& index) const
  {
    const uint32_t offset = raw_bank_offsets[index];
    return UTRawBank<decoding_version>(data + offset, raw_bank_offsets[index + 1] - offset);
  }
};
