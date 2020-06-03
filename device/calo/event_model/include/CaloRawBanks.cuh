#pragma once

#include "CudaCommon.h"

struct CaloRawBank {
  int source_id;
  int pattern;
  int code;
  unsigned size;
  uint32_t* data;

  // For Allen format
  __device__ CaloRawBank(const char* raw_bank, const unsigned s)
  : size{s}
  {
    const char* p = raw_bank;
    source_id = *((uint32_t*) p);
    p += sizeof(uint32_t);

    uint32_t trig_size = *((uint32_t*) p) & 0x7F;
    code = ( *((uint32_t*) p) >> 14 ) & 0x1FF;
    p += sizeof(uint32_t) + 4 * ((trig_size + 3) / 4); // Skip header and Trigger.

    pattern = *((uint32_t*) p);

    // Skipping pattern bits.
    data = (uint32_t*) (p + sizeof(uint32_t));
  }

  // For MEP format
  __device__ CaloRawBank(const uint32_t sid, const char* fragment, const char* end)
  {
    source_id = sid;
    size = (uint32_t*)end - (uint32_t*)fragment;

    uint32_t trig_size = *((uint32_t*) fragment) & 0x7F;
    code = ( *((uint32_t*) fragment) >> 14 ) & 0x1FF;
    fragment += sizeof(uint32_t) + 4 * ((trig_size + 3) / 4); // Skip header and Trigger.

    pattern = *((uint32_t*) fragment);

    // Skipping pattern bits.
    data = (uint32_t*) (fragment + sizeof(uint32_t));
  }


  __device__ void update(int length)
  {
    char* p = (char*) (data + length);
    uint32_t trig_size = *((uint32_t*) p) & 0x7F;
    code = ( *((uint32_t*) p) >> 14 ) & 0x1FF;
    p += sizeof(uint32_t) + 4 * ((trig_size + 3) / 4); // Skip header and Trigger.

    pattern = *((uint32_t*) p);

    // Skipping pattern bits.
    data = (uint32_t*) (p + sizeof(uint32_t));
  }

  __device__ int get_length()
  {
    #ifdef __CUDACC__
    int c = __popc(pattern);
    #else
    int c = __builtin_popcount(pattern);
    #endif
    return 12 * c + 4 * (32 - c);
  }
};
