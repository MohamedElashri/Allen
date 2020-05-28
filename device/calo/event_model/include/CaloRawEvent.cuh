#pragma once

#include "CudaCommon.h"
#include "CaloRawBanks.cuh"

struct CaloRawEvent {
  uint32_t number_of_raw_banks;
  const char* data;
  const uint32_t* offsets;

  // For Allen format
  __device__ CaloRawEvent(const char* events, const uint32_t* o)
  : number_of_raw_banks{((uint32_t*) events)[0]},
    data{events},
    offsets{o}
  {
  }

  __device__ CaloRawBank bank(unsigned event, unsigned n) {
    const char* event_data = data + offsets[event];
    uint32_t* bank_offsets = ((uint32_t*)event_data) + 1;
    return CaloRawBank{event_data + (number_of_raw_banks + 2) * sizeof(uint32_t) + bank_offsets[n],
        bank_offsets[n + 1] - bank_offsets[n]};
  }
};

struct CaloMepEvent {
  uint32_t number_of_raw_banks;
  const char* blocks;
  const uint32_t* offsets;

  // For Allen format
  __device__ CaloMepEvent(const char* b, const uint32_t* o)
  : number_of_raw_banks{MEP::number_of_banks(o)},
    blocks{b},
    offsets{o}
  {
  }

  __device__ CaloRawBank bank(unsigned event, unsigned n) {
    return MEP::raw_bank<CaloRawBank>(blocks, offsets, event, n);
  }
};
