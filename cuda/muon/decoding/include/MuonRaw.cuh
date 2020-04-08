#pragma once

#include <cstdint>
#include <cassert>

namespace Muon {
  struct MuonRawBank {
    uint32_t sourceID;
    uint16_t* data;
    uint16_t* last;
    size_t m_size;

    __device__ MuonRawBank(const char* raw_bank, const char* end)
    {
      const char* p = raw_bank;
      sourceID = *((uint32_t*) p);
      p += sizeof(uint32_t);
      data = (uint16_t*) p;
      last = (uint16_t*) end;
      m_size = end - p;
    }

    __device__ MuonRawBank(const uint32_t sID, const char* bank_start, const char* bank_end)
    {
      sourceID = sID;
      data = (uint16_t*) bank_start;
      last = (uint16_t*) bank_end;
      m_size = bank_start - bank_end;
    }

  };

  struct MuonRawEvent {
    static constexpr size_t number_of_raw_banks = 10;
    static constexpr size_t batches_per_bank = 4;

    uint32_t* raw_bank_offset;
    char* payload;

    __device__ MuonRawEvent(const char* event)
    {
      const char* p = event;
      assert(*((uint32_t*) p) == number_of_raw_banks);
      p += sizeof(uint32_t);
      raw_bank_offset = (uint32_t*) p;
      p += (number_of_raw_banks + 1) * sizeof(uint32_t);
      payload = (char*) p;
    }

    __device__ MuonRawBank getMuonBank(const uint32_t index) const
    {
      MuonRawBank bank(payload + raw_bank_offset[index], payload + raw_bank_offset[index + 1]);
      return bank;
    }
  };
} // namespace Muon
