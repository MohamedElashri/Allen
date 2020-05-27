#pragma once

#include "CudaCommon.h"

struct CaloRawBank {
  int source_id;
  int pattern;
  int code;
  unsigned size;
  uint32_t* data;

  // For Allen format
  __device__ __host__ CaloRawBank(const char* raw_bank, const char* end)
  {
    const char* p = raw_bank;
    source_id = *((uint32_t*) p);
    p += sizeof(uint32_t);

    uint32_t trig_size = *((uint32_t*) p) & 0x7F;
    code = ( *((uint32_t*) p) >> 14 ) & 0x1FF;
    p += sizeof(uint32_t) + 4 * ((trig_size + 3) / 4); // Skip header and Trigger.

    pattern = *((uint32_t*) p);

    size = (uint32_t*)end - (uint32_t*)raw_bank;

    // Skipping pattern bits.
    data = (uint32_t*) (p + sizeof(uint32_t));
  }

  // For MEP format
  __device__ __host__ CaloRawBank(const uint32_t source_id, const char* fragment, const char* end)
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


  __device__ __host__ void update(int length)
  {
    char* p = (char*) (data + length);
    uint32_t trig_size = *((uint32_t*) p) & 0x7F;
    code = ( *((uint32_t*) p) >> 14 ) & 0x1FF;
    p += sizeof(uint32_t) + 4 * ((trig_size + 3) / 4); // Skip header and Trigger.

    pattern = *((uint32_t*) p);

    // Skipping pattern bits.
    data = (uint32_t*) (p + sizeof(uint32_t));
  }

  __device__ __host__ int get_length()
  {
    int length = 0;
    for (int i = 0; i < 32; i++) {
      length += 4 + 8 * ((pattern >> i) & 0x1);
    }
    return length;
  }
};

struct odin_data_t {
  static __host__ __device__ const uint* data(const char* dev_odin_data, const uint* dev_odin_offsets, const uint event_number) {
    // In Allen layout, the first N + 2 uint are the number of banks
    // (1 in this case) and N + 1 offsets.
    return ODINRawBank(dev_odin_data + dev_odin_offsets[event_number] + 3 * sizeof(uint32_t)).data;
  }
};

struct odin_data_mep_t {
  static __host__ __device__ const uint* data(const char* dev_odin_data, const uint* dev_odin_offsets, const uint event_number) {
    return MEP::raw_bank<ODINRawBank>(dev_odin_data, dev_odin_offsets, event_number, 0).data;
  }
};
