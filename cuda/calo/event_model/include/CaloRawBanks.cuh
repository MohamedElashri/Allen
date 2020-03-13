#pragma once

#include "CudaCommon.h"

struct CaloRawBank {
  int source_id;
  int pattern;
  int code;
  uint32_t* data;

  // Empty constructor
  __device__ __host__ CaloRawBank();

  // For Allen format
  __device__ __host__ CaloRawBank(const char* raw_bank);

  // For MEP format
  __device__ __host__ CaloRawBank(const uint32_t source_id, const char* fragment);
};
