/*****************************************************************************\
* (c) Copyright 2018-2020 CERN for the benefit of the LHCb Collaboration      *
\*****************************************************************************/
#pragma once

#include <cstdint>
#include <cassert>
#include <MEPTools.h>

namespace Muon {
  template<unsigned version>
  struct MuonRawBank {

    static_assert(version == 2 || version == 3);

    using data_type = std::conditional_t<version == 2, uint16_t, uint8_t>;

    uint32_t sourceID = 0;
    const data_type* data = nullptr;
    const data_type* last = nullptr;

    __device__ MuonRawBank(const char* raw_bank, const uint16_t s)
    {
      const char* p = raw_bank;
      sourceID = reinterpret_cast<const uint32_t*>(p)[0];
      p += sizeof(uint32_t);
      data = reinterpret_cast<const data_type*>(p);
      last = reinterpret_cast<const data_type*>(p + s);
    }

    __device__ MuonRawBank(const uint32_t sID, const char* bank_start, const uint16_t s)
    {
      sourceID = sID;
      data = reinterpret_cast<const data_type*>(bank_start);
      last = reinterpret_cast<const data_type*>(bank_start + s);
    }
  };

  template<unsigned version = 2>
  struct MuonRawEvent {
  private:
    uint32_t m_number_of_raw_banks = 0;
    const uint32_t* m_raw_bank_offset = nullptr;
    const uint16_t* m_raw_bank_sizes = nullptr;
    const char* m_payload = nullptr;

    __device__ __host__ void initialize(const char* event, const uint16_t* sizes)
    {
      const char* p = event;
      m_number_of_raw_banks = *reinterpret_cast<const uint32_t*>(p);
      p += sizeof(uint32_t);
      m_raw_bank_offset = reinterpret_cast<const uint32_t*>(p);
      p += (m_number_of_raw_banks + 1) * sizeof(uint32_t);
      m_payload = p;
      m_raw_bank_sizes = sizes;
    }

  public:
    static constexpr size_t batches_per_bank = 4;

    __device__ __host__ MuonRawEvent(const char* event, const uint16_t* sizes) { initialize(event, sizes); }

    __device__ __host__ MuonRawEvent(
      const char* dev_muon_raw_input,
      const unsigned* dev_muon_raw_input_offsets,
      const unsigned* dev_muon_raw_input_sizes,
      const unsigned event_number)
    {
      initialize(
        dev_muon_raw_input + dev_muon_raw_input_offsets[event_number],
        Allen::bank_sizes(dev_muon_raw_input_sizes, event_number));
    }

    __device__ __host__ unsigned number_of_raw_banks() const { return m_number_of_raw_banks; }

    __device__ __host__ MuonRawBank<version> raw_bank(const unsigned index) const
    {
      return MuonRawBank<version> {m_payload + m_raw_bank_offset[index], m_raw_bank_sizes[index]};
    }
  };

  template<bool mep_layout, unsigned version = 2>
  using RawEvent = std::conditional_t<mep_layout, MEP::RawEvent<MuonRawBank<version>>, MuonRawEvent<version>>;
} // namespace Muon
