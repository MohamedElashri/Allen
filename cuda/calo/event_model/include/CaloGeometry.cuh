#pragma once

#include "CudaCommon.h"

#define MAX_NEIGH 9
#define AREA_SIZE 64 * 64 * MAX_NEIGH // 4096 * 9
#define ROW_SIZE 64 * MAX_NEIGH

struct CaloGeometry {
  uint16_t neigh_offset;
  uint16_t code_offset;
  uint16_t* channels;
  uint16_t* neighbors;

  __device__ __host__ CaloGeometry(const char* raw_geometry);
};
