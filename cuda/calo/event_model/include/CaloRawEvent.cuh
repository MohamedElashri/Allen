#pragma once

#include "CudaCommon.h"

struct CaloRawEvent {
  uint32_t number_of_raw_banks;
  uint32_t* raw_bank_offset;
  char* payload;

  // For Allen format
  __device__ __host__ CaloRawEvent(const char* event);
};
