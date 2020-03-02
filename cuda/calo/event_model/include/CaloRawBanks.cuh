#pragma once

#include "CudaCommon.h"

struct CaloRawBank {
  uint32_t source_id;
  uint32_t adc_size;
  uint32_t* data;

  // Empty constructor
  __device__ __host__ CaloRawBank();

  // For Allen format
  __device__ __host__ CaloRawBank(const char* raw_bank);

  // For MEP format
  __device__ __host__ CaloRawBank(const uint32_t source_id, const char* fragment);
};
