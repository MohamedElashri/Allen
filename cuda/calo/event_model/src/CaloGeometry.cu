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
  xy = (double*) (p + xy_offset);
}
