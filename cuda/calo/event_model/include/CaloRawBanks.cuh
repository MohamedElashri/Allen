#pragma once

#include "CudaCommon.h"

struct CaloRawBank {
  uint32_t source_id;
  uint32_t* data;

  // For MEP format
  __device__ __host__ CaloRawBank(const uint32_t source_id, const char* fragment);

  // For Allen format
  __device__ __host__ CaloRawBank(const char* raw_bank);
};
