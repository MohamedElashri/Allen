#include "CaloRawEvent.cuh"

__device__ __host__ CaloRawEvent::CaloRawEvent(const char* event)
{
  const char* p = event;
  number_of_raw_banks = *((uint32_t*) p);
  p += sizeof(uint32_t);
  raw_bank_offset = (uint32_t*) p;
  p += (number_of_raw_banks + 1) * sizeof(uint32_t);
  payload = (char*) p;
}
