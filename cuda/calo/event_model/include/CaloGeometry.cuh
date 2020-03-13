#pragma once

#include "CudaCommon.h"

struct CaloGeometry {
  uint16_t code_offset;
  uint16_t* channels;

  // For Allen format
  __device__ __host__ CaloGeometry(const char* raw_geometry);
};
