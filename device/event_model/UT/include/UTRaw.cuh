/*****************************************************************************\
* (c) Copyright 2018-2020 CERN for the benefit of the LHCb Collaboration      *
\*****************************************************************************/
#pragma once

#include <stdint.h>
#include <BackendCommon.h>
#include <MEPTools.h>

template<int decoding_version>
struct UTRawBank {
  uint32_t const sourceID;
  std::array<uint32_t, 6> number_of_hits {0, 0, 0, 0, 0, 0};
  uint16_t const* data = nullptr;
  uint16_t const size = 0;

  static_assert(decoding_version == -1 || decoding_version == 3 || decoding_version == 4);

  __device__ __host__ UTRawBank(const char* ut_raw_bank, const uint16_t size) :
    UTRawBank {reinterpret_cast<const uint32_t*>(ut_raw_bank)[0], ut_raw_bank + sizeof(uint32_t), size}
  {}

  __device__ __host__
  UTRawBank(const uint32_t sID, const char* ut_fragment, const uint16_t s)
    : sourceID{sID}, size{static_cast<uint16_t>(s / sizeof(uint16_t))}
  {
    auto p = reinterpret_cast<const uint32_t*>(ut_fragment);
    if constexpr (decoding_version == 3) {
      number_of_hits[0] = *p & 0x0000FFFFU;
      p += 1;
      data = reinterpret_cast<const uint16_t*>(p);
    }
    else if constexpr (decoding_version == 4) {
      if (s >= static_cast<long>(6 * sizeof(uint32_t))) {
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

template<bool mep_layout>
struct UTRawEvent {
private:

  using sizes_t = std::conditional_t<mep_layout, uint32_t, uint16_t>;

  uint32_t m_number_of_raw_banks = 0;
  uint32_t const* m_offsets = nullptr;
  sizes_t const* m_sizes = nullptr;
  char const* m_data = nullptr;
  uint32_t const m_event = 0;

public:
  __device__ __host__ UTRawEvent(const char* data, const uint32_t* offsets, const uint32_t* sizes, uint32_t const event)
    : m_event{event}
  {
    if constexpr (mep_layout) {
      m_data = data;
      m_offsets = offsets;
      m_sizes = sizes;
    }
    else {
      m_data = data + offsets[event];
      m_sizes = Allen::bank_sizes(sizes, event);
      const char* p = m_data;
      m_number_of_raw_banks = reinterpret_cast<const uint32_t*>(p)[0];
      p += sizeof(uint32_t);
      m_offsets = reinterpret_cast<const uint32_t*>(p);
      p += (m_number_of_raw_banks + 1) * sizeof(uint32_t);
      m_data = p;
    }
  }

  uint32_t number_of_raw_banks() const { return m_number_of_raw_banks; }

  template<int decoding_version>
  __device__ __host__ UTRawBank<decoding_version> raw_bank(uint32_t const bank) const
  {
    if constexpr (mep_layout) {
      return MEP::raw_bank<UTRawBank<decoding_version>>(m_data, m_offsets, m_sizes, m_event, bank);
    }
    else {
      return UTRawBank<decoding_version>(m_data + m_offsets[bank], m_sizes[bank]);
    }
  }
};
