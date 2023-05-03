/*****************************************************************************\
* (c) Copyright 2018-2020 CERN for the benefit of the LHCb Collaboration      *
\*****************************************************************************/
#pragma once

#include <stdint.h>
#include <BackendCommon.h>
#include <MEPTools.h>
#include "SciFiDefinitions.cuh"

namespace SciFi {
  struct SciFiRawBank {
    uint32_t sourceID = 0;
    uint16_t const* data = nullptr;
    uint16_t const* last = nullptr;
    uint8_t type = Allen::LastBankType;

    __device__ __host__ SciFiRawBank(const char* raw_bank, const uint16_t s, const uint8_t t)
    {
      const char* p = raw_bank;
      sourceID = reinterpret_cast<uint32_t const*>(p)[0];
      p += sizeof(uint32_t);
      data = reinterpret_cast<uint16_t const*>(p);
      last = reinterpret_cast<uint16_t const*>(p) + (s / sizeof(uint16_t));
      type = t;
    }

    __device__ __host__ SciFiRawBank(const uint32_t sID, const char* fragment, const uint16_t s, const uint8_t t)
    {
      sourceID = sID;
      data = reinterpret_cast<uint16_t const*>(fragment);
      last = reinterpret_cast<uint16_t const*>(fragment) + (s / sizeof(uint16_t));
      type = t;
    }
  };

  struct SciFiRawEvent {
  private:
    uint32_t m_number_of_raw_banks = 0;
    uint32_t const* m_raw_bank_offset = nullptr;
    uint16_t const* m_raw_bank_sizes = nullptr;
    uint8_t const* m_raw_bank_types = nullptr;
    char const* m_payload = nullptr;

    __device__ __host__ void initialize(const char* event, const uint16_t* sizes, const uint8_t* types = nullptr)
    {
      const char* p = event;
      m_number_of_raw_banks = reinterpret_cast<uint32_t const*>(p)[0];
      p += sizeof(uint32_t);
      m_raw_bank_offset = reinterpret_cast<uint32_t const*>(p);
      p += (m_number_of_raw_banks + 1) * sizeof(uint32_t);
      m_raw_bank_sizes = sizes;
      m_raw_bank_types = types;
      m_payload = p;
    }

  public:
    // FIXME: temporarily keep this one until types is properly propagated everywhere.
    __device__ __host__ SciFiRawEvent(const char* event, const uint16_t* sizes) { initialize(event, sizes); }

    // FIXME: temporarily keep this one until types is properly propagated everywhere.
    __device__ __host__ SciFiRawEvent(
      const char* dev_scifi_raw_input,
      const unsigned* dev_scifi_raw_input_offsets,
      const unsigned* dev_scifi_raw_input_sizes,
      const unsigned event_number)
    {
      const uint16_t* sizes = Allen::bank_sizes(dev_scifi_raw_input_sizes, event_number);
      initialize(dev_scifi_raw_input + dev_scifi_raw_input_offsets[event_number], sizes);
    }

    __device__ __host__ SciFiRawEvent(const char* event, const uint16_t* sizes, const uint8_t* types)
    {
      initialize(event, sizes, types);
    }

    __device__ __host__ SciFiRawEvent(
      const char* dev_scifi_raw_input,
      const unsigned* dev_scifi_raw_input_offsets,
      const unsigned* dev_scifi_raw_input_sizes,
      const unsigned* dev_scifi_raw_input_types,
      const unsigned event_number)
    {
      const uint16_t* sizes = Allen::bank_sizes(dev_scifi_raw_input_sizes, event_number);
      const uint8_t* types = Allen::bank_types(dev_scifi_raw_input_types, event_number);
      initialize(dev_scifi_raw_input + dev_scifi_raw_input_offsets[event_number], sizes, types);
    }

    __device__ __host__ unsigned number_of_raw_banks() const { return m_number_of_raw_banks; }

    __device__ __host__ SciFiRawBank raw_bank(const unsigned index) const
    {
      auto type = m_raw_bank_types == nullptr ? uint8_t {0} : m_raw_bank_types[index];
      return SciFiRawBank {m_payload + m_raw_bank_offset[index], m_raw_bank_sizes[index], type};
    }

    // get bank size in bytes, subtract four bytes for header word
    __device__ __host__ unsigned bank_size(const unsigned index) const { return m_raw_bank_sizes[index] - 4; }

    // get bank type
    __device__ __host__ unsigned bank_type(const unsigned index) const
    {
      return m_raw_bank_types == nullptr ? uint8_t {0} : m_raw_bank_types[index];
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
    return reverse_raw_bank_order ? 5 * (index / 5) + (4 - index % 5) : index;
  }

  //  template<>
  __device__ inline unsigned int getRowInMap(const SciFi::SciFiRawBank rawbank, const SciFi::SciFiGeometry& geom)
  {
    unsigned int iRowInMap = iSource(geom, rawbank.sourceID);
    if (iRowInMap == geom.number_of_banks) return iRowInMap; // HACK: to be replaced by proper error treatment
    return iRowInMap;
  }

  __device__ inline std::pair<uint16_t const*, uint16_t const*> readAndCheckRawBank(const SciFi::SciFiRawBank rawbank)
  {
    // FIXME: This should be included in contracts. See Allen#
    uint16_t const* starting_it = rawbank.data;
    uint16_t const* last = rawbank.last;
    // Skip empty raw banks: very unlikely, as there should always be a header. But it has been seen in early data
    // taking.
    if (last - starting_it < 2) {
      return std::make_pair(rawbank.last, rawbank.last);
    }
    starting_it += 2;                                    // skip header
    if (starting_it != last && *(last - 1) == 0) --last; // Remove padding at the end
    if (starting_it >= last || starting_it >= rawbank.last) {
      return std::make_pair(rawbank.last, rawbank.last);
    }
    if (
      (last - starting_it + 1) >
      SciFi::SciFiRawBankParams::nbClusMaximum * SciFi::SciFiRawBankParams::BankProperties::NbLinksPerBank) {
      return std::make_pair(rawbank.last, rawbank.last);
    }
    return std::make_pair(starting_it, last);
  }

} // namespace SciFi
