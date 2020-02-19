#include <CaloRawBanks.cuh>

__device__ __host__ CaloRawBank::CaloRawBank(const char* raw_bank)
{
  const char* p = raw_bank;
  source_id = *((uint32_t*) p);
  p += sizeof(uint32_t);
  data = (uint32_t*) p;
}

__device__ __host__ CaloRawBank::CaloRawBank(const uint32_t sid, const char* fragment)
{
  source_id = sid;
  data = (uint32_t*) fragment;
}
