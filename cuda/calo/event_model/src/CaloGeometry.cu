#include "CaloGeometry.cuh"

__device__ __host__ CaloGeometry::CaloGeometry(const char* raw_geometry)
{
  const char* p = raw_geometry;
  code_offset = *((uint16_t*) raw_geometry);
  channels = (uint16_t*) (p + sizeof(uint16_t)); // Skip code offset.
}
