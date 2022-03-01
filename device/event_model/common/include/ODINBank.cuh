/*****************************************************************************\
* (c) Copyright 2020 CERN for the benefit of the LHCb Collaboration           *
\*****************************************************************************/
#pragma once

#include <BackendCommon.h>
#include <MEPTools.h>

struct ODINRawBank {

  uint32_t const* data;
  unsigned short size = 0;

  /// Constructor from Allen layout
  __device__ __host__ ODINRawBank(const char* raw_bank, uint16_t s)
  {
    // The source ID is the first number in the bank in Allen layout,
    // skip it.
    data = reinterpret_cast<uint32_t const*>(raw_bank) + 1;
    size = s / sizeof(uint32_t);
    // All known ODIN banks consist of 10 words
    assert(size = 10);
  }

  /// Constructor from MEP layout
  __device__ __host__ ODINRawBank(const uint32_t, const char* fragment, uint16_t s)
  {
    data = reinterpret_cast<uint32_t const*>(fragment);
    size = s / sizeof(uint32_t);
    // All known ODIN banks consist of 10 words
    assert(size = 10);
  }
};

template<bool mep_layout>
static __host__ __device__ ODINRawBank
odin_bank(const char* dev_odin_data, const uint* dev_odin_offsets, const uint* dev_odin_sizes, const uint event_number)
{
  if constexpr(mep_layout) {
    return MEP::raw_bank<ODINRawBank>(dev_odin_data, dev_odin_offsets, dev_odin_sizes, event_number, 0);
  }
  else {
    // In Allen layout the first uint is the number of raw banks,
    // which should always be one. This is followed by N+1 offsets. As there
    // is only 1 banks, there are two offsets.
    char const* event_data = dev_odin_data + dev_odin_offsets[event_number];
    assert(reinterpret_cast<uint32_t const*>(event_data)[0] == 1);
    auto const size_offset = dev_odin_sizes[event_number];
    auto const size = reinterpret_cast<unsigned short const*>(dev_odin_sizes)[size_offset];

    return ODINRawBank(event_data + 3 * sizeof(uint32_t), size);
  }
}
