#include <CaloRawBanks.cuh>

__device__ __host__ CaloRawBank::CaloRawBank() {
}

__device__ __host__ CaloRawBank::CaloRawBank(const char* raw_bank)
{
  const char* p = raw_bank;
  source_id = *((uint32_t*) p);
  p += sizeof(uint32_t);

  uint32_t trig_size = *((uint32_t*) p) & 0x7F;
  code = ( *((uint32_t*) p) >> 14 ) & 0x1FF;
  p += sizeof(uint32_t) + 4 * ((trig_size + 3) / 4); // Skip header and Trigger.

  pattern = *((uint32_t*) p);

  // Skipping pattern bits.
  data = (uint32_t*) (p + sizeof(uint32_t));
}

__device__ __host__ CaloRawBank::CaloRawBank(const uint32_t sid, const char* fragment)
{
  source_id = sid;

  uint32_t trig_size = *((uint32_t*) fragment) & 0x7F;
  code = ( *((uint32_t*) fragment) >> 14 ) & 0x1FF;
  fragment += sizeof(uint32_t) + 4 * ((trig_size + 3) / 4); // Skip header and Trigger.

  pattern = *((uint32_t*) fragment);

  // Skipping pattern bits.
  data = (uint32_t*) (fragment + sizeof(uint32_t));
}
