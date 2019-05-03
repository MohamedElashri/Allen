#pragma once

#include <stdint.h>

namespace Muon {
  struct MuonRawBank {
    uint32_t sourceID;
    uint16_t* data;
    uint16_t* last;
    size_t m_size;

    __device__ MuonRawBank(const char* raw_bank, const char* end) {
      const char* p = raw_bank;
      sourceID = *((uint32_t*) p);
      p += sizeof(uint32_t);
      data = (uint16_t*) p;
      last = (uint16_t*) end;
      m_size = end - p;
    }
  };

  struct MuonRawEvent {
    uint32_t number_of_raw_banks;
    uint32_t* raw_bank_offset;
    char* payload;

    __device__ MuonRawEvent(const char* event) {
      const char* p = event;
      number_of_raw_banks = *((uint32_t*) p);
      p += sizeof(uint32_t);
      raw_bank_offset = (uint32_t*) p;
      p += (number_of_raw_banks + 1) * sizeof(uint32_t);
      payload = (char*) p;
    }

    __device__ MuonRawBank getMuonBank(const uint32_t index) const {
      MuonRawBank bank(payload + raw_bank_offset[index], payload + raw_bank_offset[index + 1]);
      return bank;
    }
  };
}
