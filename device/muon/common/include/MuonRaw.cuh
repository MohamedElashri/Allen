/*****************************************************************************\
* (c) Copyright 2018-2020 CERN for the benefit of the LHCb Collaboration      *
\*****************************************************************************/
#pragma once

#include <cstdint>
#include <cassert>
#include <MEPTools.h>

namespace Muon {
  struct MuonRawBank {
    uint32_t sourceID;
    uint16_t* data;
    uint16_t* last;

    __device__ MuonRawBank(const char* raw_bank, const char* end)
    {
      const char* p = raw_bank;
      sourceID = *((uint32_t*) p);
      p += sizeof(uint32_t);
      data = (uint16_t*) p;
      last = (uint16_t*) end;
    }

    __device__ MuonRawBank(const uint32_t sID, const char* bank_start, const char* bank_end)
    {
      sourceID = sID;
      data = (uint16_t*) bank_start;
      last = (uint16_t*) bank_end;
    }
  };

  struct MuonRawEvent {
  private:
    uint32_t m_number_of_raw_banks;
    uint32_t* m_raw_bank_offset;
    char* m_payload;

    __device__ __host__ void initialize(const char* event)
    {
      const char* p = event;
      m_number_of_raw_banks = *((uint32_t*) p);
      p += sizeof(uint32_t);
      m_raw_bank_offset = (uint32_t*) p;
      p += (m_number_of_raw_banks + 1) * sizeof(uint32_t);
      m_payload = (char*) p;
    }

  public:
    static constexpr size_t batches_per_bank = 4;

    __device__ __host__ MuonRawEvent(const char* event) { initialize(event); }

    __device__ __host__ MuonRawEvent(
      const char* dev_scifi_raw_input,
      const unsigned* dev_scifi_raw_input_offsets,
      const unsigned event_number)
    {
      initialize(dev_scifi_raw_input + dev_scifi_raw_input_offsets[event_number]);
    }

    __device__ __host__ unsigned number_of_raw_banks() const { return m_number_of_raw_banks; }

    __device__ __host__ MuonRawBank raw_bank(const unsigned index) const
    {
      return MuonRawBank {m_payload + m_raw_bank_offset[index], m_payload + m_raw_bank_offset[index + 1]};
    }
  };

  template<bool mep_layout>
  using RawEvent = std::conditional_t<mep_layout, MEP::RawEvent<MuonRawBank>, MuonRawEvent>;
} // namespace Muon
