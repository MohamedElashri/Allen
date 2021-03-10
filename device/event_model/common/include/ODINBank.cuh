/*****************************************************************************\
* (c) Copyright 2020 CERN for the benefit of the LHCb Collaboration           *
\*****************************************************************************/
#pragma once

#include <BackendCommon.h>
#include <MEPTools.h>

struct ODINRawBank {

  uint32_t const* data;

  /// Constructor from Allen layout
  __device__ __host__ ODINRawBank(const char* raw_bank)
  {
    // The source ID is the first number in the bank in Allen layout,
    // skip it.
    data = reinterpret_cast<uint32_t const*>(raw_bank) + 1;
  }

  /// Constructor from MEP layout
  __device__ __host__ ODINRawBank(const uint32_t, const char* fragment) { data = (uint32_t*) fragment; }
};

struct odin_data_t {
  static __host__ __device__ const unsigned*
  data(const char* dev_odin_data, const uint* dev_odin_offsets, const uint event_number)
  {
    // In Allen layout the first uint is the number of raw banks,
    // which should always be one. This is followed by N+1 offsets. As there
    // is only 1 banks, there are two offsets.
    char const* event_data = dev_odin_data + dev_odin_offsets[event_number];
    assert(reinterpret_cast<uint32_t const*>(event_data)[0] == 1);

    return ODINRawBank(event_data + 3 * sizeof(uint32_t)).data;
  }
};

struct odin_data_mep_t {
  static __host__ __device__ const unsigned*
  data(const char* dev_odin_data, const uint* dev_odin_offsets, const uint event_number)
  {
    return MEP::raw_bank<ODINRawBank>(dev_odin_data, dev_odin_offsets, event_number, 0).data;
  }
};
