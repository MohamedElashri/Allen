#include "CaloGeometry.cuh"

__device__ __host__ CaloGeometry::CaloGeometry(const char* raw_geometry)
{
  const char* p = raw_geometry;
  uint32_t neigh_offset = *((uint32_t*) p);
  p = p + sizeof(uint32_t); // Skip neighbors offset.
  uint32_t xy_offset = *((uint32_t*) p);
  p = p + sizeof(uint32_t); // Skip xy offset.
  code_offset = *((uint16_t*) p);
  p = p + sizeof(uint16_t); // Skip code offset.
  channels = (uint16_t*) p;
  neighbors = (uint16_t*) (p + neigh_offset);
  // printf("XY offset: %d\n", xy_offset);
  xy = (uint16_t*) (p + xy_offset);
}


// Use the bits of 4 uint16_ts to create a single double.
// Needed to avoid misaligned address bug (as opposed to direct interpretation as double).
__device__ __host__ double CaloGeometry::getX(uint16_t cellid) {
  uint64_t x = ((uint64_t) xy[cellid * XY_SIZE + 3] << 48) +
               ((uint64_t) xy[cellid * XY_SIZE + 2] << 32) +
               ((uint64_t) xy[cellid * XY_SIZE + 1] << 16) +
               ((uint64_t) xy[cellid * XY_SIZE]);

  return *((double*) &x);
}

__device__ __host__ double CaloGeometry::getY(uint16_t cellid) {
  uint64_t y = ((uint64_t) xy[cellid * XY_SIZE + 4 + 3] << 48) +
               ((uint64_t) xy[cellid * XY_SIZE + 4 + 2] << 32) +
               ((uint64_t) xy[cellid * XY_SIZE + 4 + 1] << 16) +
               ((uint64_t) xy[cellid * XY_SIZE]);

  return *((double*) &y);
}