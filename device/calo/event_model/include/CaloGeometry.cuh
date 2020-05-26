#pragma once

#include "CudaCommon.h"

#define MAX_NEIGH 9
#define AREA_SIZE 64 * 64 * MAX_NEIGH // 4096 * 9
#define ROW_SIZE 64 * MAX_NEIGH
#define XY_SIZE 2 * 4 // 8 to accomodate for 2 64 bit doubles as uint16_ts

struct CaloGeometry {
  uint16_t code_offset;
  uint16_t* channels;
  uint16_t* neighbors;
  uint16_t* xy; // We have to use 16 bits ints here instead of doubles as using doubles caused a misaligned address bug.

  __device__ __host__ CaloGeometry(const char* raw_geometry);

  __device__ __host__ double getX(uint16_t cellid);
  __device__ __host__ double getY(uint16_t cellid);
};
