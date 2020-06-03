#pragma once

#include "CudaCommon.h"

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

  __device__ __host__ float getX(uint16_t cellid) const {
    return xy[2 * cellid];
  }

  __device__ __host__ float getY(uint16_t cellid) const {
    return xy[2 * cellid + 1];
  }

};
