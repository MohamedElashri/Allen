/*****************************************************************************\
* (c) Copyright 2018-2020 CERN for the benefit of the LHCb Collaboration      *
\*****************************************************************************/
#pragma once

#include <stdint.h>
#include <BackendCommon.h>
#include <MEPTools.h>

namespace SciFi {
  struct SciFiRawBank {
    uint32_t sourceID;
    uint16_t* data;
    uint16_t* last;

    __device__ __host__ SciFiRawBank(const char* raw_bank, const uint16_t s)
    {
      const char* p = raw_bank;
      sourceID = *((uint32_t*) p);
      p += sizeof(uint32_t);
      data = (uint16_t*) p;
      last = data + s / sizeof(uint16_t);
    }

    __device__ __host__ SciFiRawBank(const uint32_t sID, const char* fragment, const uint16_t s)
    {
      sourceID = sID;
      data = (uint16_t*) fragment;
      last = data + s / sizeof(uint16_t);
    }
  };

  struct SciFiRawEvent {
  private:
    uint32_t m_number_of_raw_banks = 0;
    uint32_t const* m_raw_bank_offset = nullptr;
    uint16_t const* m_raw_bank_sizes = nullptr;
    char const* m_payload = nullptr;

    __device__ __host__ void initialize(const char* event, const uint16_t* sizes)
    {
      const char* p = event;
      m_number_of_raw_banks = *((uint32_t*) p);
      p += sizeof(uint32_t);
      m_raw_bank_offset = (uint32_t*) p;
      p += (m_number_of_raw_banks + 1) * sizeof(uint32_t);
      m_raw_bank_sizes = sizes;
      m_payload = (char*) p;
    }

  public:
    __device__ __host__ SciFiRawEvent(const char* event, const uint16_t* sizes) { initialize(event, sizes); }

    __device__ __host__ SciFiRawEvent(
      const char* dev_scifi_raw_input,
      const unsigned* dev_scifi_raw_input_offsets,
      const unsigned* dev_scifi_raw_input_sizes,
      const unsigned event_number)
    {
      const uint16_t* sizes = Allen::bank_sizes(dev_scifi_raw_input_sizes, event_number);
      initialize(dev_scifi_raw_input + dev_scifi_raw_input_offsets[event_number], sizes);
    }

    __device__ __host__ unsigned number_of_raw_banks() const { return m_number_of_raw_banks; }

    __device__ __host__ SciFiRawBank raw_bank(const unsigned index) const
    {
      return SciFiRawBank {m_payload + m_raw_bank_offset[index], m_raw_bank_sizes[index]};
    }

    // get bank size in bytes, subtract four bytes for header word
    __device__ __host__ unsigned bank_size(const unsigned index) const
    {
      return m_raw_bank_sizes[index] - 4;
    }
  };

  /**
   * @brief RawEvent view for both MEP and MDF.
   */
  template<bool mep_layout>
  using RawEvent = std::conditional_t<mep_layout, MEP::RawEvent<SciFiRawBank>, SciFiRawEvent>;

  __device__ inline uint32_t getRawBankIndexOrderedByX(const uint32_t index)
  {
    const unsigned k = index % 10; // Rawbank relative to zone
    // Reverse rawbank order when on the left side of a zone (because module order is M4–M0)
    const bool reverse_raw_bank_order = k < 5;
    // if reversed: index = offset(5 rb/zone) + reversed index within zone
    return reverse_raw_bank_order ? 5 * (index / 5) + (4 - index % 5) : index;
  }
} // namespace SciFi
