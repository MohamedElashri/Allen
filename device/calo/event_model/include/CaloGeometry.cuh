#pragma once

#include "CudaCommon.h"

#define MAX_NEIGH 9
#define AREA_SIZE 64 * 64 * MAX_NEIGH // 4096 * 9
#define ROW_SIZE 64 * MAX_NEIGH
#define XY_SIZE 2 * 4 // 8 to accomodate for 2 64 bit doubles as uint16_ts

struct CaloGeometry {
  uint32_t code_offset;
  uint16_t* channels;
  uint16_t* neighbors;
  float* xy; // We have to use 16 bits ints here instead of doubles as using doubles caused a misaligned address bug.
  const unsigned max_cellid;

  __device__ __host__ CaloGeometry(const char* raw_geometry, const unsigned max)
  : max_cellid{max}
  {
    const char* p = raw_geometry;
    uint32_t neigh_offset = *((uint32_t*) p);
    p = p + sizeof(uint32_t); // Skip neighbors offset.
    uint32_t xy_offset = *((uint32_t*) p);
    p = p + sizeof(uint32_t); // Skip xy offset.
    code_offset = *((uint32_t*) p);
    p = p + sizeof(uint32_t); // Skip code offset.
    channels = (uint16_t*) p;
    neighbors = (uint16_t*) (p + neigh_offset);
    // printf("XY offset: %d\n", xy_offset);
    xy = (float*) (p + xy_offset);
  }
};
