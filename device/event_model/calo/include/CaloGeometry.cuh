#pragma once
#include <iostream>
#include <iomanip>

#include "CaloConstants.cuh"
#include "BackendCommon.h"

struct CaloGeometry {
  uint32_t code_offset;
  uint32_t max_index;
  float pedestal;
  uint16_t* channels;
  uint16_t* neighbors;
  float* xy;
  float* gain;

  __device__ __host__ CaloGeometry(const char* raw_geometry)
  {
    const char* p = raw_geometry;
    code_offset = *((uint32_t*) p);
    p += sizeof(uint32_t); // Skip code offset.
    max_index = *((uint32_t*) p);
    p += sizeof(uint32_t); // Skip max_index.
    pedestal = *((float*) p);
    p += sizeof(float); // Skip pedestal
    const auto channels_size = *((uint32_t*) p);
    p += sizeof(uint32_t); // Skip channel size
    channels = (uint16_t*) p;
    p += sizeof(uint16_t) * channels_size;
    const auto neighbors_size = *((uint32_t*) p);
    p += sizeof(uint32_t); // Skip neighbours size
    neighbors = (uint16_t*) p;
    p += sizeof(uint16_t) * neighbors_size;
    const uint32_t xy_size = *((uint32_t*) p);
    p += sizeof(uint32_t); // Skip xy size
    xy = (float*) p;
    p += sizeof(float) * xy_size;
    // const uint32_t gain_size = *((uint32_t*) p);
    p += sizeof(uint32_t); // Skip gain size
    gain = (float*) p;
  }

  __device__ __host__ float getX(uint16_t cellid) const { return xy[2 * cellid]; }

  __device__ __host__ float getY(uint16_t cellid) const { return xy[2 * cellid + 1]; }
};
